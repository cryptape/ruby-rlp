# -*- encoding : ascii-8bit -*-
require 'test_helper'

class RLPTest < Minitest::Test
  include RLP

  def test_rlp_class_method
    bytes = code_array_to_bytes([0x00, 0x7f])
    assert_equal encode(bytes), RLP.encode(bytes)
  end

  def test_encode_short_string
    bytes = code_array_to_bytes([0x00, 0x7f])
    assert_equal str_to_bytes("\x82\x00\x7f"), encode(bytes)
  end

  def test_encode_with_pyrlp_fixtures
    msg_format = "Test %s failed (encoded %s to %s instead of %s)"

    fixtures = load_json_fixtures File.expand_path('../rlptest.json', __FILE__)
    fixtures.each do |(name, in_out)|
      data = to_bytes in_out['in']
      expect = in_out['out'].upcase
      result = encode_hex(encode(data)).upcase
      if result != expect
        fail msg_format % [name, data, result, expect]
      end
    end
  end

  def test_descend
    rlp = RLP.encode [1, [2, [3, [4, [5]]]]]

    assert_equal RLP.encode(1), RLP.descend(rlp, 0)
    assert_equal RLP.encode(2), RLP.descend(rlp, 1, 0)
    assert_equal RLP.encode(5), RLP.descend(rlp, 1, 1, 1, 1, 0)

    assert_equal RLP.encode([3,[4,[5]]]), RLP.descend(rlp, 1, 1)
    assert_equal RLP.encode([5]), RLP.descend(rlp, 1, 1, 1, 1)
  end

  def test_append
    rlp = RLP.encode [1, [2,3]]
    assert_equal RLP.encode([1, [2,3], 4]), RLP.append(rlp, 4)

    rlp = RLP.encode [1]
    assert_equal RLP.encode([1, [2,3], 4]), RLP.append(RLP.append(rlp, [2,3]), 4)
  end

  def test_insert
    rlp = RLP.encode [1, 2, 3]
    assert_equal RLP.encode([4, 1, 2, 3]), RLP.insert(rlp, 0, 4)
    assert_equal RLP.encode([1, 2, 3, 4]), RLP.insert(rlp, 3, 4)
    assert_equal RLP.encode([1, 2, 4, 3]), RLP.insert(rlp, 2, 4)
    assert_equal RLP.encode([1, 2, 5, 4, 3]), RLP.insert(RLP.insert(rlp, 2, 4), 2, 5)
  end

  def test_pop
    rlp = RLP.encode [1, 2, 3, 4, 5]
    assert_equal RLP.encode([2,3,4,5]), RLP.pop(rlp, 0)
    assert_equal RLP.encode([1,2,3,4]), RLP.pop(rlp, 4)
    assert_equal RLP.encode([1,2,4,5]), RLP.pop(rlp, 2)
    assert_equal RLP.encode([3,4,5]), RLP.pop(RLP.pop(rlp, 0), 0)
    assert_equal RLP.encode([1,2,3,4]), RLP.pop(rlp)
  end

  def test_compare_length
    rlp = RLP.encode [1,2,3,4,5]
    assert_equal -1, RLP.compare_length(rlp, 100)
    assert_equal 1, RLP.compare_length(rlp, 1)
    assert_equal 0, RLP.compare_length(rlp, 5)

    rlp = RLP.encode []
    assert_equal 0, RLP.compare_length(rlp, 0)
    assert_equal 1, RLP.compare_length(rlp, -1)
    assert_equal -1, RLP.compare_length(rlp, 1)
  end

  def test_favor_short_string_form
    rlp = Utils.decode_hex 'b8056d6f6f7365'
    assert_raises(DecodingError) { RLP.decode(rlp) }

    rlp = Utils.decode_hex '856d6f6f7365'
    assert_equal 'moose', RLP.decode(rlp)
  end

end
