require 'rlp/constant'
require 'rlp/data'
require 'rlp/error'
require 'rlp/utils'
require 'rlp/sedes'

require 'rlp/encode'
require 'rlp/decode'

module RLP
  include Encode
  include Decode

  extend self
end
