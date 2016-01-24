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

    [[], [1,2], 0...500].each do |s|
      assert_equal s, l1.deserialize(l1.serialize(s))
    end

  end
end
