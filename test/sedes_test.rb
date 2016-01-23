require 'test_helper'

class SedesTest < Minitest::Test
  include RLP

  def test_inference
    obj_sedes_pairs = [
      [5, Sedes.big_endian_int],
      [0, Sedes.big_endian_int],
      [-1, nil],
      ['', Sedes.binary],
      ['asdf', Sedes.binary],
      ['\xe4\xf6\xfc\xea\xe2\xfb', Sedes.binary],
      [[], Sedes::List.new],
      [[1, 2, 3], Sedes::List.new(elements: [Sedes.big_endian_int]*3)],
      [[[], 'asdf'], Sedes::List.new(elements: [[], Sedes.binary])],
    ]

    obj_sedes_pairs.each do |(obj, sedes)|
      if sedes
        inferred = Sedes.infer obj
        assert_equal sedes, inferred
        sedes.serialize(obj)
      else
        assert_raises ArgumentError do
          Sedes.infer obj
        end
      end
    end
  end

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

#TODO: CountableList
  end

end
