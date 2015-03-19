require 'minitest/autorun'
require 'fileutils'
require 'google_drive'

# Test the client lib!
class TestGoogleDrive < MiniTest::Test
  def setup
    @drive = ::GoogleDrive.new
    @old_sheet_file_id = '0AiOYF21HkoowdEZ4Ukkyc09nb2czQUxUYldidTB4Q1E'
    @new_sheet_file_id = '1vIICbbfHJ8lYSthiDWTNypZulrMResi9zPRjv4ePJJU'
    @doc_file_id = '1lH-Nr_8UBOkvk8OdcdFoDez3OFIJxkawGVkwlMB-BjQ'
  end

  def test_find
    file = @drive.find @old_sheet_file_id
    assert_equal file['title'], 'Example Middleman Google Drive worksheet'

    file = @drive.find @new_sheet_file_id
    assert_equal file['title'], 'Example Middleman Google Drive worksheet'
  end

  def test_export
    content = @drive.export @doc_file_id, :txt
    assert_nil content =~ /^<html>/

    content = @drive.export @doc_file_id, :html
    assert_not_nil content =~ /^<html>/
  end

  def test_export_to_file
    filename = @drive.export_to_file(@doc_file_id, :html)
    assert_equal '.html', File.extname(filename)
    assert File.exist?(filename), "Export file is missing #{filename}"
    assert_not_nil File.read(filename) =~ /^<html>/
    File.unlink(filename)

    [@new_sheet_file_id, @old_sheet_file_id].each do |file_id|
      filename = @drive.export_to_file(file_id, :xlsx)
      assert_equal '.xlsx', File.extname(filename)
      assert File.exist?(filename), "Export file is missing #{filename}"
      File.unlink(filename)
    end
  end

  def test_prepare_spreadsheet
    [@old_sheet_file_id, @new_sheet_file_id].each do |file_id|
      #filename = "/tmp/google_drive_#{file_id}.xlsx"
      filename = @drive.export_to_file(file_id, :xlsx)
      assert_equal '.xlsx', File.extname(filename)
      assert File.exist?(filename), "Export file is missing #{filename}"
      data = @drive.prepare_spreadsheet(filename)
      assert_has_key data, 'microcopy'
      assert_has_key data['microcopy'], 'help'
      File.unlink(filename)
    end
  end

  def test_copy_file
  end

  def assert_has_key(hash, key, msg=nil)
    assert hash.key?(key), msg || "The key '#{key}' is missing from #{hash}"
  end

  def assert_not_nil(thing, msg=nil)
    assert !thing.nil?, msg
  end
end
