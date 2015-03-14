require 'middleman-core'
require 'google_drive'
require 'archieml'

module Middleman
  module GoogleDrive
    # Middle man extension that loads the google doc data
    class Extension < Middleman::Extension
      option :load_sheets, {}, 'Key for a google spreadsheet or a hash of google spreadsheets to load. Hash value is the id or slug of the spreadsheet to load, hash key is the data attribute to load the sheet data into.'
      option :load_docs, {}, 'Key for a google doc or a hash of google docs to load as text. Hash value is the Google key of the spreadsheet to load, hash key is the data attribute to load the content into.'
      option :load_docs_html, {}, 'Key for a google doc or a hash of google docs to load as HTML. Hash value is the Google key of the spreadsheet to load, hash key is the data attribute to load the content into.'
      option :load_docs_archieml, {}, 'Key for a google doc or a hash of google docs to load and parse as ArchieML. Hash value is the Google key of the spreadsheet to load, hash key is the data attribute to load the content into.'

      def initialize(klass, options_hash = {}, &block)
        super

        @drive = ::GoogleDrive.new

        @app = klass.inst

        handle_option(options.load_sheets, 'spreadsheet')
        handle_option(options.load_docs, 'text')
        handle_option(options.load_docs_html, 'html')
        handle_option(options.load_docs_archieml, 'archieml')
      end

      def handle_option(option, type)
        if option.is_a? Hash
          option.each do |name, key|
            store_data(name, load_doc(key.to_s, type))
          end
        elsif type == 'spreadsheet'
          load_doc(option.to_s, type).each do |name, sheet|
            store_data(name, sheet)
          end
        else
          store_data('doc', load_doc(option.to_s, type))
        end
      rescue Faraday::ConnectionFailed => exc
        if @drive.server?
          puts "== FAILED to load Google Doc \"#{exc.message}\""
        else
          puts <<-MSG
== Could not connect to Google Drive. Local data will be used.
MSG
        end
      rescue GoogleDrive::GoogleDriveError => exc
        if @drive.server?
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
          @drive.clear_auth
        end
      end

      def load_doc(key, type)
        case type.to_s
        when 'spreadsheet'
          data = @drive.prepared_spreadsheet(key)
        when 'html'
          data = @drive.doc(key, 'html')
        when 'archieml'
          data = Archieml.load(@drive.doc(key, 'text'))
        else
          data = @drive.doc(key, 'text')
        end
        doc = @drive.find(key)
        puts <<-MSG
== Loaded data from Google Doc "#{doc['title']}"
==   #{doc['alternateLink']}
        MSG
        data
      end

      def store_data(key, data)
        backup_file = File.join(@app.root, @app.data_dir, "#{key}.json")
        File.open(backup_file, 'w') do |f|
          f.write(JSON.pretty_generate(data))
        end
        @app.data.store(key, data)
      end
    end
  end
end
