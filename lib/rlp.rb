# -*- encoding : ascii-8bit -*-

require 'rlp/constant'
require 'rlp/data'
require 'rlp/error'
require 'rlp/utils'
require 'rlp/sedes'

require 'rlp/encode'
require 'rlp/decode'

require 'rlp/decode_lazy'
require 'rlp/lazy_list'

module RLP
  include Encode
  include Decode
  include DecodeLazy

  extend self

  EMPTYLIST = encode([]).freeze

end
