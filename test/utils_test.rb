# -*- encoding : ascii-8bit -*-

require 'test_helper'

class UtilsTest < Minitest::Test
  include RLP::Utils

  def test_bytes_to_str
    assert_equal 'UTF-8', bytes_to_str("abc").encoding.name
  end

  def test_str_to_bytes
    assert_equal 'ASCII-8BIT', str_to_bytes("abc").encoding.name
  end

  def test_big_endian_to_int
    int = [0, 100000, 100000000, 2**256-1]
    bytes = ["\x00", "\x01\x86\xa0", "\x05\xf5\xe1\x00", "\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff"].map {|s| s }

    int.zip(bytes).each do |i, b|
      assert_equal i, big_endian_to_int(b)
    end
  end

  def test_int_to_big_endian
    int = [0, 100000, 100000000, 2**256-1]
    bytes = ["\x00", "\x01\x86\xa0", "\x05\xf5\xe1\x00", "\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff"].map {|s| s }

    int.zip(bytes).each do |i, b|
      assert_equal b, int_to_big_endian(i)
    end
  end

  def test_encode_hex
    assert_equal "", encode_hex("")
    assert_equal "616263", encode_hex("abc")
  end

  def test_decode_hex
    assert_equal "", decode_hex("")
    assert_equal "abc", decode_hex("616263")
    assert_raises(TypeError) { decode_hex('xxxx') }
    assert_raises(TypeError) { decode_hex('\x00\x00') }
  end

end
