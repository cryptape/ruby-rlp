# -*- encoding : ascii-8bit -*-
require 'test_helper'

class BigEndianIntSedesTest < Minitest::Test
  include RLP

  @@random_integers = [256, 257, 4839, 849302, 483290432, 483290483290482039482039,
                       48930248348219540325894323584235894327865439258743754893066]

  def test_negative_int
    negative_int = [-1, -100, -255, -256, -2342423]
    negative_int.each do |n|
      assert_raises(SerializationError) { Sedes.big_endian_int.serialize(n) }
    end
  end

  def test_serialization
    assert @@random_integers[-1] < 2**256

    @@random_integers.each do |n|
      serial = Sedes.big_endian_int.serialize(n)
      deserial = Sedes.big_endian_int.deserialize(serial)
      assert_equal n, deserial
      assert serial[0] != "\x00" if n != 0
    end
  end

  def test_single_byte
    (1...256).each do |n|
      c = n.chr

      serial = Sedes.big_endian_int.serialize(n)
      assert_equal c, serial

      deserial = Sedes.big_endian_int.deserialize(serial)
      assert_equal n, deserial
    end
  end

  def test_valid_data
    [ [256, str_to_bytes("\x01\x00")],
      [1024, str_to_bytes("\x04\x00")],
      [65535, str_to_bytes("\xFF\xFF")]
    ].each do |(n, s)|
      serial = Sedes.big_endian_int.serialize(n)
      deserial = Sedes.big_endian_int.deserialize(serial)
      assert_equal s, serial
      assert_equal n, deserial
    end
  end

  def test_fixed_length
    s = Sedes::BigEndianInt.new(4)

    [0, 1, 255, 256, 256**3, 256**4 - 1].each do |i|
      assert_equal 4, s.serialize(i).size
      assert_equal i, s.deserialize(s.serialize(i))
    end

    [256**4, 256**4 + 1, 256**5, -1 -256, 'asdf'].each do |i|
      assert_raises(SerializationError) { s.serialize(i) }
    end
  end
end
