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

        handle_option(options.load_sheets, :xlsx)
        handle_option(options.load_docs, :txt)
        handle_option(options.load_docs_html, :html)
        handle_option(options.load_docs_archieml, :archieml)
      end

      def handle_option(option, type)
        if option.is_a? Hash
          option.each do |name, key|
            store_data(name, load_doc(key.to_s, type))
          end
        elsif type == :xlsx
          load_doc(option.to_s, type).each do |name, sheet|
            store_data(name, sheet)
          end
        else
          store_data('doc', load_doc(option.to_s, type))
        end
      end

      def load_doc(key, type)
        doc = @drive.find(key)
        puts <<-MSG
== Loading data from Google Doc "#{doc['title']}"
==   #{doc['alternateLink']}
        MSG
        filename = data_path("#{key}.#{type}")

        case type.to_sym
        when :xlsx
          if @drive.server?
            filename = @drive.export_to_file(key, :xlsx)
          else
            @drive.export_to_file(key, :xlsx, filename)
          end
          ret = @drive.prepare_spreadsheet(filename)
          File.unlink(filename) if @drive.server?
        when :archieml
          if @drive.server?
            ret = Archieml.load(@drive.export(key, :txt))
          else
            @drive.export_to_file(key, :txt, filename)
            ret = Archieml.load(File.read(filename))
          end
        else
          if @drive.server?
            ret = @drive.export(key, type)
          else
            @drive.export_to_file(key, type, filename)
            ret = File.read(filename)
          end
        end
        return ret
      rescue ::Faraday::ConnectionFailed => exc
        puts "== FAILED to load Google Doc \"#{exc.message}\""
        return load_local_copy(filename)
      rescue ::GoogleDrive::GoogleDriveError => exc
        puts "== FAILED to load Google Doc \"#{exc.message}\""
        unless @drive.server?
          puts <<-MSG

Could not load the Google Doc.

Things to check:
- Make sure the Google Doc key is correct
- Make sure you're logging in with the correct account
- Make sure you have access to the document

          MSG
          @drive.clear_auth
        end
        return load_local_copy(filename)
      end

      def load_local_copy(filename)
        if File.exist? filename
          puts '== Loading Google Doc from local cache'
          type = File.extname(filename).gsub('.','').to_sym
          case type
          when :xlsx
            return @drive.prepare_spreadsheet(filename)
          when :archieml
            return Archieml.load(File.read(filename))
          else
            return File.read(filename)
          end
        else
          puts '== No local copy of Google Doc'
          return nil
        end
      end

      def data_path(basename)
        File.join(@app.root, @app.data_dir, basename)
      end

      def store_data(key, data)
        @app.data.store(key, data)
      end
    end
  end
end
