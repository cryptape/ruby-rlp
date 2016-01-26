require 'rlp'

include RLP

include Constant
include Utils

$address   = Sedes::Binary.fixed_length 20, allow_empty: true
$int20     = Sedes::BigEndianInt.new 20
$int32     = Sedes::BigEndianInt.new 32
$int256    = Sedes::BigEndianInt.new 256
$hash32    = Sedes::Binary.fixed_length 32
$trie_root = Sedes::Binary.fixed_length 32, allow_empty: true

def zpad(x, l)
  "#{BYTE_ZERO*[0, l-x.size].max}#{x}"
end

class Transaction
  include Sedes::Serializable

  set_serializable_fields(
    nonce:    Sedes.big_endian_int,
    gasprice: Sedes.big_endian_int,
    startgas: Sedes.big_endian_int,
    to:       $address,
    value:    Sedes.big_endian_int,
    data:     Sedes.binary,
    v:        Sedes.big_endian_int,
    r:        Sedes.big_endian_int,
    s:        Sedes.big_endian_int
  )

  def initialize(options)
    super({v: 0, r: 0, s: 0}.merge(options))
  end
end

class BlockHeader
  include Sedes::Serializable

  set_serializable_fields(
    prevhash:      $hash32,
    uncles_hash:   $hash32,
    coinbase:      $address,
    state_root:    $trie_root,
    tx_list_root:  $trie_root,
    receipts_root: $trie_root,
    bloom:         $int256,
    difficulty:    Sedes.big_endian_int,
    number:        Sedes.big_endian_int,
    gas_limit:     Sedes.big_endian_int,
    gas_used:      Sedes.big_endian_int,
    timestamp:     Sedes.big_endian_int,
    extra_data:    Sedes.binary,
    mixhash:       Sedes.binary,
    nonce:         Sedes.binary
  )
end

class Block
  include Sedes::Serializable

  set_serializable_fields(
    header: BlockHeader,
    transaction_list: Sedes::CountableList.new(Transaction),
    uncles: Sedes::CountableList.new(BlockHeader)
  )

  def initialize(options)
    super({transaction_list: [], uncles: []}.merge(options))
  end
end
