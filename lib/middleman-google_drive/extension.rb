require 'roo'

module Middleman
  module GoogleDrive
    # Middle man extension that loads the google doc data
    class Extension < Middleman::Extension
      option :load_sheets, {}, 'Hash of google spreadsheets to load. Hash value is the id or slug of the entry to load, hash key is the data attribute to load the sheet data into.'

      def initialize(klass, options_hash = {}, &block)
        super

        @client = Middleman::GoogleDrive.connect
        @drive = @client.discovered_api('drive', 'v2')

        app = klass.inst # this is obviously where you would store the app instance
        options.load_sheets.each do |k, v|
          app.data.store(k, get_sheet(v))
        end
      end

      def get_sheet(key)
        data = {}
        # we're gonna request the spreadsheet in excel format
        format = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

        # get the file metadata
        list_resp = @client.execute(
          api_method: @drive.files.get,
          parameters: { fileId: key })

        # die if there's an error
        fail list_resp.error_message if list_resp.error?

        # grab the export url
        uri = list_resp.data['exportLinks'][format]

        # get the export
        get_resp = @client.execute(uri: uri)

        # die if there's an error
        fail get_resp.error_message if get_resp.error?

        # get a temporary file. we can't just write to it because ruby's
        # tempfile tries to be clever and open the file for you, except we
        # need to open the file in binary mode, so thanks ruby.
        fp = Tempfile.new(['gdoc', '.xlsx'])
        filename = fp.path
        fp.close

        # since the export is binary, reopen the tempfile in write binary mode
        open(filename, 'wb') do |f|
          # write the digits
          f.write get_resp.body
        end

        # now open the file a third time with Roo. (Roo can't handle an IO
        # object, it will only take filenames or urls, coulda done this all
        # in memory, but alas...)
        xls = Roo::Spreadsheet.open(filename)
        xls.each_with_pagename do |title, sheet|
          # if the sheet is called microcopy or copy, we assume the first
          # column contains keys and the second contains values. Ala tarbell.
          if %w(microcopy copy).include? title.downcase
            data[title] = {}
            sheet.each do |row|
              data[title][row[0]] = row[1]
            end
          else
            # otherwise parse the sheet into a dict, incorrectly, of course
            sheet.header_line = 2 # this is stupid. theres a bug in Roo.
            data[title] = sheet.parse(headers: true)
          end
        end
        fp.unlink # delete our tempfile
        data
      end
    end
  end
end
