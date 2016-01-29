require 'test_helper'

class DecodeLazyTest < Minitest::Test
  include RLP

  def evaluate(obj)
    if obj.instance_of?(LazyList)
      obj.map {|e| evaluate(e) }
    else
      obj
    end
  end

  def test_empty_list
    dec = ->{ decode_lazy encode([]) }

    assert_instance_of LazyList, dec.call

    assert_raises(IndexError) { dec.call.fetch(0) }
    assert_raises(IndexError) { dec.call.fetch(1) }

    assert_equal 0, dec.call.size
    assert_equal [], evaluate(dec.call)
  end

  def test_string
    ["", "asdf", "a"*56, "b"*123].each do |s|
      dec = ->{ decode_lazy encode(s) }

      assert_instance_of String, dec.call
      assert_equal s.size, dec.call.size
      assert_equal s, dec.call

      #assert_equal s, peek(encode(s), []) # TODO: implement peek
      #assert_raises(IndexError) { peek(encode(s), 0) }
      #assert_raises(IndexError) { peek(encode(s), [0] }
    end
  end

  def test_nested_list
    l = [[], ["a"], ["b", "c", "d"]]
    dec = ->{ decode_lazy encode(l) }

    assert_instance_of LazyList, dec.call
    assert_equal l.size, dec.call.size
    assert_equal l, evaluate(dec.call)

    assert_raises(IndexError) { dec.call.fetch(0).fetch(0) }
    assert_raises(IndexError) { dec.call.fetch(1).fetch(1) }
    assert_raises(IndexError) { dec.call.fetch(2).fetch(3) }
    assert_raises(IndexError) { dec.call.fetch(3) }
  end

  def test_sedes
    ls = [[], [1], [3,2,1]]
    ls.each {|l| assert_equal l, evaluate(decode_lazy(encode(l), sedes: Sedes.big_endian_int)) }

    sedes = Sedes::CountableList.new(Sedes.big_endian_int)
    l = [[], [1,2], "asdf", [3]]
    invalid_lazy = decode_lazy encode(l), sedes: sedes

    assert_equal l[0], invalid_lazy[0]
    assert_equal l[1], invalid_lazy[1]
    assert_raises(DeserializationError) { invalid_lazy[2] }
  end

  def test_peek
    # TODO: test peek
  end

end
