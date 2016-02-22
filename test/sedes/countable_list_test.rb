# -*- encoding : ascii-8bit -*-
require 'test_helper'

class CountableListSedesTest < Minitest::Test
  include RLP

  def test_coordinate_with_list
    l1 = Sedes::List.new
    l2 = Sedes::List.new elements: [Sedes.big_endian_int, Sedes.big_endian_int]

    c = Sedes::CountableList.new Sedes.big_endian_int

    assert_equal [].freeze, l1.deserialize(c.serialize([]))

    [[1], [1,2,3], 0...30, [4,3]].each do |l|
      s = c.serialize l
      assert_raises(DeserializationError) { l1.deserialize(s) }
    end

    [[1,2], [3,4], [9,8]].each do |v|
      s = c.serialize(v)
      assert_equal v, l2.deserialize(s)
    end

    [[], [1], [1,2,3]].each do |v|
      assert_raises(DeserializationError) { l2.deserialize(c.serialize(v)) }
    end
  end

  def test_countable_list_sedes
    l1 = Sedes::CountableList.new Sedes.big_endian_int

    [[], [1,2], (0...500).to_a].each do |s|
      assert_equal s, l1.deserialize(l1.serialize(s))
    end

    [[1, 'asdf'], ['asdf'], [1, [2]], [[]]].each do |n|
      assert_raises(SerializationError) { l1.serialize(n) }
    end

    l2 = Sedes::CountableList.new Sedes::CountableList.new(Sedes.big_endian_int)

    [[], [[]], [[1,2,3], [4]], [[5], [6,7,8]], [[], [], [9,0]]].each do |s|
      assert_equal s, l2.deserialize(l2.serialize(s))
    end

    [[[[]]], [1,2], [1, ['asdf'], ['fdsa']]].each do |n|
      assert_raises(SerializationError) { l2.serialize(n) }
    end

    l3 = Sedes::CountableList.new Sedes.big_endian_int, max_length: 3

    [[], [1], [1,2], [1,2,3]].each do |s|
      serial = l3.serialize(s)
      assert_equal l1.serialize(s), serial
      assert_equal s, l3.deserialize(serial)
    end

    [[1,2,3,4], [1,2,3,4,5,6,7], (0...500).to_a].each do |n|
      assert_raises(SerializationError) { l3.serialize(n) }

      serial = l1.serialize(n)
      assert_raises(DeserializationError) { l3.deserialize(serial) }

      ll = decode_lazy(encode(serial))
      assert_raises(DeserializationError) { l3.deserialize(ll) }
      assert_equal 3+1, ll.instance_variable_get(:@elements).size
    end
  end
end
