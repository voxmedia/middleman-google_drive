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

        app = klass.inst
        app.set :drive, drive # so you can access the drive api directly
        options.load_sheets.each do |k, v|
          loop do
            begin
              app.data.store(k, drive.prepared_spreadsheet(v))
              doc = drive.find(v)
              puts <<-MSG
== Loaded data.#{k} from Google Doc "#{doc['title']}"
==   #{doc['alternateLink']}
              MSG
              break
            rescue ::GoogleDrive::GoogleDriveError => exc
              if drive.server?
                puts "== FAILED to load Google Doc \"#{exc.message}\""
                break
              end

              puts <<-MSG

Could not load the Google Doc.

Things to check:
- Make sure the Google Doc key is correct
- Make sure you're logging in with the correct account
- Make sure you have access to the document

Google said "#{exc.message}." It might be a lie.

Would you like to try again? [Y/n]
              MSG
              resp = $stdin.read 1
              break unless resp.strip.empty? || resp =~ /[Yy]/

              drive.redo_auth
            end
          end
        end
      end
    end
  end
end
