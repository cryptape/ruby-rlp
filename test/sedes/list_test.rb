require 'test_helper'

class ListSedesTest < Minitest::Test
  include RLP

  def test_list_sedes
    l1 = Sedes::List.new
    l2 = Sedes::List.new elements: [Sedes.big_endian_int, Sedes.big_endian_int]
    l3 = Sedes::List.new elements: [l1, l2, [[[]]]]

    assert_raises(SerializationError) { l1.serialize([[]]) }
    assert_raises(SerializationError) { l1.serialize([5]) }

    [[], [1,2,3], [1, [2,3], 4]].each do |d|
      assert_raises(SerializationError) { l2.serialize(d) }
    end

    [[], [[], [], [[[]]]], [[], [5,6], [[]]]].each do |d|
      assert_raises(SerializationError) { l3.serialize(d) }
    end
  end
end
