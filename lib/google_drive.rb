require 'middleman-google_drive/version'
require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/file_storage'
require 'google/api_client/auth/installed_app'
require 'rubyXL'

# Convience wrapper for Google Drive
#
# You can override the location of the client secrets and oauth2 JSON files with
# the environment variables `GOOGLE_CLIENT_SECRETS` and `GOOGLE_DRIVE_OAUTH`.
#
# If you plan to run Middleman on a server, you can use Google's server to server
# authentication. This will kick in if you define the environment variables
# `GOOGLE_OAUTH_PERSON`, `GOOGLE_OAUTH_ISSUER` and either `GOOGLE_OAUTH_KEYFILE`
# or `GOOGLE_OAUTH_PRIVATE_KEY`.
class GoogleDrive
  # Google API Client object
  attr_reader :client

  # Constructor. Loads all params from envionment variables.
  def initialize
    @credentials = ENV['GOOGLE_DRIVE_OAUTH'] || File.expand_path(
      '~/.google_drive_oauth2.json')
    @client_secrets = ENV['GOOGLE_CLIENT_SECRETS'] || File.expand_path(
      '~/.google_client_secrets.json')

    @person = ENV['GOOGLE_OAUTH_PERSON']
    @issuer = ENV['GOOGLE_OAUTH_ISSUER']
    @key_path = ENV['GOOGLE_OAUTH_KEYFILE']
    @private_key = ENV['GOOGLE_OAUTH_PRIVATE_KEY']

    # try to read the file,
    # throw errors if not readable or not found
    if @key_path
      @key = Google::APIClient::KeyUtils.load_from_pkcs12(
        @key_path, 'notasecret')
    elsif @private_key
      @key = OpenSSL::PKey::RSA.new(
        @private_key, 'notasecret')
    end

    @_files = {}
    @_spreadsheets = {}

    do_auth
  end

  # Find a Google Drive file
  # Takes the key of a Google Drive file and returns a hash of meta data. The returned hash is
  # formatted as a
  # {Google Drive resource}[https://developers.google.com/drive/v2/reference/files#resource].
  #
  # @param file_id [String] file id
  # @return [Hash] file meta data
  def find(file_id)
    return @_files[file_id] unless @_files[file_id].nil?

    drive = @client.discovered_api('drive', 'v2')

    # get the file metadata
    resp = @client.execute(
      api_method: drive.files.get,
      parameters: { fileId: file_id })

    # die if there's an error
    fail GoogleDriveError, resp.error_message if resp.error?

    @_files[file_id] = resp.data
  end

  # Download and parse a spreadsheet
  # Returns a {RubyXL Workbook}[http://www.rubydoc.info/gems/rubyXL/3.3.7/RubyXL/Workbook]
  #
  # @param file_id [String] file id
  # @return [RubyXL::Workbook] Excel workbook
  def spreadsheet(file_id)
    list_resp = find(file_id)

    # Grab the export url. We're gonna request the spreadsheet
    # in excel format. Because it includes all the worksheets.
    uri = list_resp['exportLinks'][
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']

    # get the export
    get_resp = @client.execute(uri: uri)

    # die if there's an error
    fail GoogleDriveError, get_resp.error_message if get_resp.error?

    # get a temporary file. The export is binary, so open the tempfile in
    # write binary mode
    fp = Tempfile.new(['gdoc', '.xlsx'], binmode: true)
    filename = fp.path
    fp.write get_resp.body
    fp.close

    # now open the file with spreadsheet
    ret = RubyXL::Parser.parse(filename)

    fp.unlink # delete our tempfile

    ret
  end

  # Download and parse a spreadsheet
  # Reduces the spreadsheet to a no-frills hash, suitable for serializing and passing around.
  #
  # @param file_id [String] file id
  # @return [Hash] spreadsheet contents
  def prepared_spreadsheet(file_id)
    xls = spreadsheet(file_id)
    data = {}
    xls.worksheets.each do |sheet|
      title = sheet.sheet_name
      # if the sheet is called microcopy, copy or ends with copy, we assume
      # the first column contains keys and the second contains values.
      # Like tarbell.
      if %w(microcopy copy).include?(title.downcase) ||
          title.downcase =~ /[ -_]copy$/
        data[title] = load_microcopy(sheet.extract_data)
      else
        # otherwise parse the sheet into a hash
        data[title] = load_table(sheet.extract_data)
      end
    end
    data
  end

  # Take a two-dimensional array from a spreadsheet and create a hash. The first
  # column is used as the key, and the second column is the value. If the key
  # occurs more than once, the value becomes an array to hold all the values
  # associated with the key.
  #
  # @param table [Array<Array>] 2d array of cell values
  # @return [Hash] spreadsheet contents
  def load_microcopy(table)
    data = {}
    table.each_with_index do |row, i|
      next if i == 0 # skip the header row
      # Did we already create this key?
      if data.keys.include? row[0]
        # if the key name is reused, create an array with all the entries
        if data[row[0]].is_a? Array
          data[row[0]] << row[1]
        else
          data[row[0]] = [data[row[0]], row[1]]
        end
      else
        # add this row's key and value to the hash
        data[row[0]] = row[1]
      end
    end
    data
  end

  # Take a two-dimensional array from a spreadsheet and create an array of hashes.
  #
  # @param table [Array<Array>] 2d array of cell values
  # @return [Array<Hash>] spreadsheet contents
  def load_table(table)
    return [] if table.length < 2
    header = table.shift # Get the header row
    table.map do |row|
      # zip headers with current row, convert it to a hash
      header.zip(row).to_h unless row.nil?
    end
  end

  # Retrieve the content of a Google Doc
  #
  # @param file_id [String] file id
  # @param format [:html, :text] format to download from google
  # @return [String] text or html
  def doc(file_id, format = :html)
    doc = find(file_id)

    # Grab the export url.
    if format.to_sym == :html
      uri = doc['exportLinks']['text/html']
    else
      uri = doc['exportLinks']['text/plain']
    end

    # get the export
    resp = @client.execute(uri: uri)

    # die if there's an error
    fail GoogleDriveError, resp.error_message if resp.error?

    resp.body
  end

  # Make a copy of a Google Drive file
  #
  # @param file_id [String] file id
  # @param title [String] title for the newly created file
  # @return [Hash] hash containing the id/key and url of the new file
  def copy(file_id, title = nil)
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
  alias_method :copy_doc, :copy

  # Delete cached credentials
  def clear_auth
    File.delete @credentials if @key.nil?
  end

  # Authenticate with Google and create the @client object
  def do_auth
    if local?
      @client = Google::APIClient.new(
        application_name: 'Middleman',
        application_version: Middleman::GoogleDrive::VERSION
      )
      begin
        file_storage = Google::APIClient::FileStorage.new(@credentials)
      rescue URI::InvalidURIError
        File.delete @credentials
        file_storage = Google::APIClient::FileStorage.new(@credentials)
      end
      if file_storage.authorization.nil?
        unless File.exist? @client_secrets
          fail ConfigurationError, 'You need to create a client_secrets.json file and save it to ~/.google_client_secrets.json.'
        end
        puts <<-MSG

Please login via your web browser. We opened the tab for you...

        MSG
        client_secrets = Google::APIClient::ClientSecrets.load(@client_secrets)
        flow = Google::APIClient::InstalledAppFlow.new(
          client_id: client_secrets.client_id,
          client_secret: client_secrets.client_secret,
          scope: ['https://www.googleapis.com/auth/drive']
        )
        @client.authorization = flow.authorize(file_storage)
      else
        @client.authorization = file_storage.authorization
      end
    else
      @client = Google::APIClient.new(
        application_name: 'Middleman',
        application_version: Middleman::GoogleDrive::VERSION,
        authorization: Signet::OAuth2::Client.new(
          token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
          audience: 'https://accounts.google.com/o/oauth2/token',
          person: @person,
          issuer: @issuer,
          signing_key: @key,
          scope: ['https://www.googleapis.com/auth/drive']
        )
      )
      @client.authorization.fetch_access_token!
    end
    nil
  end

  # Returns true if we're using a private key to autheticate (like on a server).
  # @return [Boolean]
  def server?
    !local?
  end

  # Returns true if we're using local oauth2 (like on your computer).
  # @return [Boolean]
  def local?
    @key.nil?
  end

  class GoogleDriveError < StandardError; end
  class DoesNotExist < GoogleDriveError; end
  class CreateError < GoogleDriveError; end
  class ConfigurationError < GoogleDriveError; end
end
