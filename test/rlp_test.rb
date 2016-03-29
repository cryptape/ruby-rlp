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
end
