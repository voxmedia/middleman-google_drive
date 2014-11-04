require 'minitest/autorun'
require 'google_drive'

# Test the client lib!
class TestChorusApiClient < MiniTest::Test
  def setup
    @drive = ::GoogleDrive.new
  end

  def test_old_find
    file = @drive.find '0AiOYF21HkoowdEZ4Ukkyc09nb2czQUxUYldidTB4Q1E'
    assert_equal file['title'], 'Example Middleman Google Drive worksheet'
  end

  def test_old_prepared_spreadsheet
    file = @drive.prepared_spreadsheet '0AiOYF21HkoowdEZ4Ukkyc09nb2czQUxUYldidTB4Q1E'
    assert_has_key file, 'microcopy'
    assert_has_key file['microcopy'], 'help'
  end

  def test_new_find
    file = @drive.find '1vIICbbfHJ8lYSthiDWTNypZulrMResi9zPRjv4ePJJU'
    assert_equal file['title'], 'Example Middleman Google Drive worksheet'
  end

  def test_new_prepared_spreadsheet
    file = @drive.prepared_spreadsheet '1vIICbbfHJ8lYSthiDWTNypZulrMResi9zPRjv4ePJJU'
    assert_has_key file, 'microcopy'
    assert_has_key file['microcopy'], 'help'
  end

  def test_new_doc
    file = @drive.doc '1lH-Nr_8UBOkvk8OdcdFoDez3OFIJxkawGVkwlMB-BjQ'
    assert_not_nil file =~ /^<html>/

    file = @drive.doc '1lH-Nr_8UBOkvk8OdcdFoDez3OFIJxkawGVkwlMB-BjQ', 'text'
    assert_nil file =~ /^<html>/
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
