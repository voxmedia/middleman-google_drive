require "google_drive"

module Middleman
  module GoogleDrive
    class Extension < Middleman::Extension
      option :load_sheets, {}, 'Hash of google spreadsheets to load. Hash value is the id or slug of the entry to load, hash key is the data attribute to load the sheet data into.'

      def initialize(app, options_hash={}, &block)
        super

        @client = Middleman::GoogleDrive.connect
        @session = GoogleDrive.login_with_oauth(c.authorization.access_token)
      end

      def after_configuration
        options.load_sheets.each do |k,v|
          app.data.store(k, get_sheet(v))
        end
      end

      def get_sheet(key)
        data = {}
        s = @session.spreadsheet_by_key(key)
        data[:title] = s.title
        s.worksheets.each do |sheet|
          data[sheet.title] = sheet.list.to_hash_array
        end
        data
      end
    end
  end
end
