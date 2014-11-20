require 'middleman-core'
require 'google_drive'

module Middleman
  module GoogleDrive
    # Middle man extension that loads the google doc data
    class Extension < Middleman::Extension
      option :load_sheets, {}, 'Key for a google spreadsheet or a hash of google spreadsheets to load. Hash value is the id or slug of the spreadsheet to load, hash key is the data attribute to load the sheet data into.'

      def initialize(klass, options_hash = {}, &block)
        super

        drive = ::GoogleDrive.new

        app = klass.inst
        app.set :drive, drive # so you can access the drive api directly
        if options.load_sheets.is_a? String
          load_doc(options.load_sheets).each do |name, sheet|
            app.data.add(name, sheet)
          end
        else
          options.load_sheets.each do |name, key|
            app.data.add(name, load_doc(key))
          end
        end
      end

      def load_doc(key)
        data = drive.prepared_spreadsheet(v)
        doc = drive.find(v)
        puts <<-MSG
== Loaded data.#{k} from Google Doc "#{doc['title']}"
==   #{doc['alternateLink']}
        MSG
        data
      rescue ::GoogleDrive::GoogleDriveError => exc
        if drive.server?
          puts "== FAILED to load Google Doc \"#{exc.message}\""
        else
          puts <<-MSG

Could not load the Google Doc.

Things to check:
- Make sure the Google Doc key is correct
- Make sure you're logging in with the correct account
- Make sure you have access to the document

Google said "#{exc.message}." It might be a lie.
          MSG
          drive.clear_auth
        end
      end

    end
  end
end
