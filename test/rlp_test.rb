require 'test_helper'

class RLPTest < Minitest::Test
  def test_encode_single_byte
    bytes = code_array_to_bytes([0x00, 0x7f])
    assert_equal bytes, RLP.encode(bytes)
  end
end
