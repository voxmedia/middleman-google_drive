require 'middleman-google_drive/version'
require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/file_storage'
require 'google/api_client/auth/installed_app'

class GoogleDrive
  def initialize
    credentials = ENV['GOOGLE_DRIVE_OAUTH'] || File.expand_path(
      '~/.google_drive_oauth2.json')
    client_secrets = ENV['GOOGLE_CLIENT_SECRETS'] || File.expand_path(
      '~/.google_client_secrets.json')

    person = ENV['GOOGLE_OAUTH_PERSON']
    issuer = ENV['GOOGLE_OAUTH_ISSUER']
    key_path = ENV['GOOGLE_OAUTH_KEYFILE']
    private_key = ENV['GOOGLE_OAUTH_PRIVATE_KEY']

    # try to read the file,
    # throw errors if not readable or not found
    if key_path
      key = Google::APIClient::KeyUtils.load_from_pkcs12(
        key_path, 'notasecret')
    elsif @private_key
      key = OpenSSL::PKey::RSA.new(
        private_key, 'notasecret')
    end

    if key
      @client = Google::APIClient.new(
        application_name: 'Middleman',
        application_version: Middleman::GoogleDrive::VERSION,
        authorization: Signet::OAuth2::Client.new(
          token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
          audience: 'https://accounts.google.com/o/oauth2/token',
          person: person,
          issuer: issuer,
          signing_key: key,
          scope: ['https://www.googleapis.com/auth/drive']
        )
      )
      @client.authorization.fetch_access_token!
    else
      @client = Google::APIClient.new(
        application_name: 'Middleman',
        application_version: Middleman::GoogleDrive::VERSION
      )
      begin
        file_storage = Google::APIClient::FileStorage.new(credentials)
      rescue URI::InvalidURIError
        File.delete credentials
        file_storage = Google::APIClient::FileStorage.new(credentials)
      end
      if file_storage.authorization.nil?
        unless File.exist? client_secrets
          fail ConfigurationError, 'You need to create a client_secrets.json file and save it to ~/.google_client_secrets.json.'
        end
        puts 'Please login via your web browser'
        client_secrets = Google::APIClient::ClientSecrets.load(client_secrets)
        flow = Google::APIClient::InstalledAppFlow.new(
          client_id: client_secrets.client_id,
          client_secret: client_secrets.client_secret,
          scope: ['https://www.googleapis.com/auth/drive']
        )
        @client.authorization = flow.authorize(file_storage)
      else
        @client.authorization = file_storage.authorization
      end
    end
  end

  def get_sheet(key)
    require 'roo'
    # setup the hash that we will eventually return
    data = {}
    drive = @client.discovered_api('drive', 'v2')

    # get the file metadata
    list_resp = @client.execute(
      api_method: drive.files.get,
      parameters: { fileId: key })

    # die if there's an error
    fail list_resp.error_message if list_resp.error?

    # Grab the export url. We're gonna request the spreadsheet
    # in excel format. Because it includes all the worksheets.
    uri = list_resp.data['exportLinks'][
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']

    # get the export
    get_resp = @client.execute(uri: uri)

    # die if there's an error
    fail get_resp.error_message if get_resp.error?

    # get a temporary file. The export is binary, so open the tempfile in
    # write binary mode
    fp = Tempfile.new(['gdoc', '.xlsx'], binmode: true)
    filename = fp.path
    fp.write get_resp.body
    fp.close

    # now open the file with Roo. (Roo can't handle an IO
    # object, it will only take filenames or urls, coulda done this all
    # in memory, but alas...)
    xls = Roo::Spreadsheet.open(filename)
    xls.each_with_pagename do |title, sheet|
      # if the sheet is called microcopy, copy or ends with copy, we assume
      # the first column contains keys and the second contains values.
      # Like tarbell.
      if %w(microcopy copy).include?(title.downcase) ||
          title.downcase =~ /[ -_]copy$/
        data[title] = {}
        sheet.each do |row|
          # if the key name is reused, create an array with all the entries
          if data[title].keys.include? row[0]
            if data[title][row[0]].is_a? Array
              data[title][row[0]] << row[1]
            else
              data[title][row[0]] = [data[title][row[0]], row[1]]
            end
          else
            data[title][row[0]] = row[1]
          end
        end
      else
        # otherwise parse the sheet into a hash
        sheet.header_line = 2 # this is stupid. theres a bug in Roo.
        data[title] = sheet.parse(headers: true)
      end
    end
    fp.unlink # delete our tempfile
    data
  end

  def copy_doc(file_id, title=nil)
    drive = @client.discovered_api('drive', 'v2')

    if title.nil?
      copied_file = drive.files.copy.request_schema.new
    else
      copied_file = drive.files.copy.request_schema.new('title' => title)
    end
    cp_resp = @client.execute(
      api_method: drive.files.copy,
      body_object: copied_file,
      parameters: { fileId: file_id, visibility: 'PRIVATE' })

    if cp_resp.error?
      fail CreateError, cp_resp.error_message
    else
      return { id: cp_resp.data['id'], url: cp_resp.data['alternateLink'] }
    end
  end

  class CreateError < Exception; end
  class ConfigurationError < Exception; end
end
