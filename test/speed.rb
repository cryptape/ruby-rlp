# -*- encoding : ascii-8bit -*-
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

def zpad(x, l)
  "#{BYTE_ZERO*[0, l-x.size].max}#{x}"
end

def rand_bytes(num=32)
  zpad(Sedes.big_endian_int.serialize(rand(2**(num*8))), num)
end
alias rand_bytes32 rand_bytes

def rand_address
  rand_bytes(20)
end

def rand_bytes8
  rand_bytes(8)
end

def rand_bigint
  rand(2**256)
end

def rand_int
  rand(2**32)
end

rand_map = {
  $hash32 => rand_bytes32,
  $trie_root => rand_bytes32,
  Sedes.binary => rand_bytes32,
  $address => rand_address,
  Sedes::Binary => rand_bytes8,
  Sedes.big_endian_int => rand_int,
  $int256 => rand_bigint
}

def mk_transaction
  Transaction.new(
    nonce:    rand_int,
    gasprice: rand_int,
    startgas: rand_int,
    to:       rand_address,
    value:    rand_int,
    data:     rand_bytes32,
    v:        27,
    r:        rand_bigint,
    s:        rand_bigint
  )
end

def mk_block_header
  BlockHeader.new(
    prevhash:      rand_bytes32,
    uncles_hash:   rand_bytes32,
    coinbase:      rand_address,
    state_root:    rand_bytes32,
    tx_list_root:  rand_bytes32,
    receipts_root: rand_bytes32,
    bloom:         rand_bigint,
    difficulty:    rand_int,
    number:        rand_int,
    gas_limit:     rand_int,
    gas_used:      rand_int,
    timestamp:     rand_int,
    extra_data:    rand_bytes32,
    mixhash:       rand_bytes32,
    nonce:         rand_bytes32
  )
end

def mk_block(num_transactions=10, num_uncles=1)
  Block.new(
    header: mk_block_header,
    transaction_list: (0...num_transactions).map {|i| mk_transaction },
    uncles: (0...num_uncles).map {|i| mk_block_header }
  )
end

def do_test_serialize(block, rounds=100)
  x = nil
  rounds.times do |i|
    x = RLP.encode(block)
  end
  x
end

def do_test_deserialize(data, rounds=100, sedes=Block)
  x = nil
  rounds.times do |i|
    x = RLP.decode(data, sedes: sedes)
  end
  x
end

def main(rounds=1000)
  st = Time.now
  d = do_test_serialize(mk_block, rounds)
  elapsed = Time.now - st
  puts "Block serializations / sec: %.2f" % (rounds/elapsed.to_f)

  st = Time.now
  d = do_test_deserialize(d, rounds)
  elapsed = Time.now - st
  puts "Block deserializations / sec: %.2f" % (rounds/elapsed.to_f)

  st = Time.now
  d = do_test_serialize(mk_transaction, rounds)
  elapsed = Time.now - st
  puts "TX serializations / sec: %.2f" % (rounds/elapsed.to_f)

  st = Time.now
  d = do_test_deserialize(d, rounds, Transaction)
  elapsed = Time.now - st
  puts "TX deserializations / sec: %.2f" % (rounds/elapsed.to_f)
end

if $0 =~ /speed.rb$/
  main
end
