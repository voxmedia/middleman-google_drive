require 'middleman-core'
require 'google_drive'

module Middleman
  module GoogleDrive
    # Middle man extension that loads the google doc data
    class Extension < Middleman::Extension
      option :load_sheets, {}, 'Hash of google spreadsheets to load. Hash value is the id or slug of the entry to load, hash key is the data attribute to load the sheet data into.'

      def initialize(klass, options_hash = {}, &block)
        super

        drive = ::GoogleDrive.new

        app = klass.inst # where would you store the app instance?
        options.load_sheets.each do |k, v|
          app.data.store(k, drive.get_sheet(v))
        end
      end
    end
  end
end
