# -*- encoding : ascii-8bit -*-

module RLP
  module Decode
    include Constant
    include Error
    include Utils

    ##
    # Decode an RLP encoded object.
    #
    # If the deserialized result `obj` has an attribute `_cached_rlp` (e.g. if
    # `sedes` is a subclass of {RLP::Sedes::Serializable}), it will be set to
    # `rlp`, which will improve performance on subsequent {RLP::Encode#encode}
    # calls. Bear in mind however that `obj` needs to make sure that this value
    # is updated whenever one of its fields changes or prevent such changes
    # entirely ({RLP::Sedes::Serializable} does the latter).
    #
    # @param sedes [#deserialize] an object implementing a function
    #   `deserialize(code)` which will be applied after decoding, or `nil` if
    #   no deserialization should be performed
    # @param strict [Boolean] if false inputs that are longer than necessary
    #   don't cause an exception
    # @param * [Hash] additional keyword arguments that will be passed to
    #   the deserializer
    #
    # @return [Object] the decoded and maybe deserialized object
    #
    # @raise [RLP::Error::DecodingError] if the input string does not end after
    #   the root item and `strict` is true
    # @raise [RLP::Error::DeserializationError] if the deserialization fails
    #
    def decode(rlp, **options)
      rlp = str_to_bytes(rlp)
      sedes = options.delete(:sedes)
      strict = options.has_key?(:strict) ? options.delete(:strict) : true

      begin
        item, next_start = consume_item(rlp, 0)
      rescue Exception => e
        raise DecodingError.new("Cannot decode rlp string: #{e}", rlp)
      end

      raise DecodingError.new("RLP string ends with #{rlp.size - next_start} superfluous bytes", rlp) if next_start != rlp.size && strict

      if sedes
        obj = sedes.instance_of?(Class) && sedes.include?(Sedes::Serializable) ?
          sedes.deserialize(item, **options) :
          sedes.deserialize(item)

        if obj.respond_to?(:_cached_rlp)
          obj._cached_rlp = rlp
          raise "RLP::Sedes::Serializable object must be immutable after decode" if obj.is_a?(Sedes::Serializable) && obj.mutable?
        end

        obj
      else
        item
      end
    end

    private

    ##
    # Read an item from an RLP string.
    #
    # * `rlp` - the string to read from
    # * `start` - the position at which to start reading`
    #
    # Returns a pair `[item, end]` where `item` is the read item and `end` is
    # the position of the first unprocessed byte.
    #
    def consume_item(rlp, start)
      t, l, s = consume_length_prefix(rlp, start)
      consume_payload(rlp, s, t, l)
    end

    ##
    # Read a length prefix from an RLP string.
    #
    # * `rlp` - the rlp string to read from
    # * `start` - the position at which to start reading
    #
    # Returns an array `[type, length, end]`, where `type` is either `:str`
    # or `:list` depending on the type of the following payload, `length` is
    # the length of the payload in bytes, and `end` is the position of the
    # first payload byte in the rlp string (thus the end of length prefix).
    #
    def consume_length_prefix(rlp, start)
      b0 = rlp[start].ord

      if b0 < PRIMITIVE_PREFIX_OFFSET # single byte
        [:str, 1, start]
      elsif b0 < PRIMITIVE_PREFIX_OFFSET + SHORT_LENGTH_LIMIT # short string
        raise DecodingError.new("Encoded as short string although single byte was possible", rlp) if (b0 - PRIMITIVE_PREFIX_OFFSET == 1) && rlp[start+1].ord < PRIMITIVE_PREFIX_OFFSET

        [:str, b0 - PRIMITIVE_PREFIX_OFFSET, start + 1]
      elsif b0 < LIST_PREFIX_OFFSET # long string
        raise DecodingError.new("Length starts with zero bytes", rlp) if rlp.slice(start+1) == BYTE_ZERO

        ll = b0 - PRIMITIVE_PREFIX_OFFSET - SHORT_LENGTH_LIMIT + 1
        l = big_endian_to_int rlp[(start+1)...(start+1+ll)]

        [:str, l, start+1+ll]
      elsif b0 < LIST_PREFIX_OFFSET + SHORT_LENGTH_LIMIT # short list
        [:list, b0 - LIST_PREFIX_OFFSET, start + 1]
      else # long list
        raise DecodingError.new('Length starts with zero bytes', rlp) if rlp.slice(start+1) == BYTE_ZERO

        ll = b0 - LIST_PREFIX_OFFSET - SHORT_LENGTH_LIMIT + 1
        l = big_endian_to_int rlp[(start+1)...(start+1+ll)]
        raise DecodingError.new('Long list prefix used for short list', rlp) if l < 56

        [:list, l, start+1+ll]
      end
    end

    ##
    # Read the payload of an item from an RLP string.
    #
    # * `rlp` - the rlp string to read from
    # * `type` - the type of the payload (`:str` or `:list`)
    # * `start` - the position at which to start reading
    # * `length` - the length of the payload in bytes
    #
    # Returns a pair `[item, end]`, where `item` is the read item and `end` is
    # the position of the first unprocessed byte.
    #
    def consume_payload(rlp, start, type, length)
      case type
      when :str
        [rlp[start...(start+length)], start+length]
      when :list
        items = []
        next_item_start = start
        payload_end = next_item_start + length

        while next_item_start < payload_end
          item, next_item_start = consume_item rlp, next_item_start
          items.push item
        end

        raise DecodingError.new('List length prefix announced a too small length', rlp) if next_item_start > payload_end

        [items, next_item_start]
      else
        raise TypeError, 'Type must be either :str or :list'
      end
    end
  end
end
