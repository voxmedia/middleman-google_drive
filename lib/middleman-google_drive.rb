require 'middleman-google_drive/version'
require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/file_storage'
require 'google/api_client/auth/installed_app'

module Middleman
  module GoogleDrive
    def self.connect
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
        puts 'authenticating with key'
        client = Google::APIClient.new(
          application_name: 'Middleman',
          application_version: Middleman::GoogleDrive::VERSION,
          authorization: Signet::OAuth2::Client.new(
            token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
            audience: 'https://accounts.google.com/o/oauth2/token',
            person: person,
            issuer: issuer,
            signing_key: key,
            scope: [
              'https://www.googleapis.com/auth/drive',
              'https://spreadsheets.google.com/feeds',
              'https://docs.google.com/feeds/',
              'https://docs.googleusercontent.com/'
            ]
          )
        )
        client.authorization.fetch_access_token!
      else
        client = Google::APIClient.new(
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
            puts 'You need to create a client_secrets.json file and save it to `~/.google_client_secrets.json`. Find instructions here: http://tarbell.readthedocs.org/en/latest/install.html#configure-google-spreadsheet-access-optional'
            exit
          end
          client_secrets = Google::APIClient::ClientSecrets.load(
            client_secrets)
          flow = Google::APIClient::InstalledAppFlow.new(
            client_id: client_secrets.client_id,
            client_secret: client_secrets.client_secret,
            scope: [
              'https://www.googleapis.com/auth/drive',
              'https://spreadsheets.google.com/feeds',
              'https://docs.google.com/feeds/',
              'https://docs.googleusercontent.com/'
            ]
          )
          client.authorization = flow.authorize(file_storage)
        else
          client.authorization = file_storage.authorization
        end
      end
      client
    end
  end
end

require 'middleman-core'
require 'middleman-google_drive/extension'

::Middleman::Extensions.register(
  :google_drive, Middleman::GoogleDrive::Extension)
