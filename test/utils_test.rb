require 'test_helper'

class UtilsTest < Minitest::Test
  include RLP::Utils

  def test_bytes_to_str
    assert_equal 'UTF-8', bytes_to_str("abc".force_encoding('ascii-8bit')).encoding.name
  end

  def test_str_to_bytes
    assert_equal 'ASCII-8BITS', str_to_bytes("abc").encoding.name
  end

  def test_int_to_big_endian
    int = [0, 100000, 100000000, 2**256-1]
    bytes = ["\x00", "\x01\x86\xa0", "\x05\xf5\xe1\x00", "\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff"].map {|s| s.force_encoding("ascii-8bit") }

    int.zip(bytes).each do |i, b|
      assert_equal b, int_to_big_endian(i)
    end
  end
end
