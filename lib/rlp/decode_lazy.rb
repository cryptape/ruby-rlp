# -*- encoding : ascii-8bit -*-

module RLP
  module DecodeLazy
    include Decode

    ##
    # Decode an RLP encoded object in a lazy fashion.
    #
    # If the encoded object is a byte string, this function acts similar to
    # {RLP::Decode#decode}. If it is a list however, a {LazyList} is returned
    # instead. This object will decode the string lazily, avoiding both
    # horizontal and vertical traversing as much as possible.
    #
    # The way `sedes` is applied depends on the decoded object: If it is a
    # string `sedes` deserializes it as a whole; if it is a list, each element
    # is deserialized individually. In both cases, `sedes_options` are passed
    # on. Note that, if a deserializer is used, only "horizontal" but not
    # "vertical lazyness" can be preserved.
    #
    # @param rlp [String] the RLP string to decode
    # @param sedes [Object] an object implementing a method `deserialize(code)`
    #   which is used as described above, or `nil` if no deserialization should
    #   be performed
    # @param sedes_options [Hash] additional keyword arguments that will be
    #   passed to the deserializers
    #
    # @return [Object] either the already decoded and deserialized object (if
    #   encoded as a string) or an instance of {RLP::LazyList}
    #
    def decode_lazy(rlp, sedes: nil, sedes_options: {})
      item, next_start = consume_item_lazy(rlp, 0)

      raise DecodingError.new("RLP length prefix announced wrong length", rlp) if next_start != rlp.size

      if item.instance_of?(LazyList)
        item.sedes = sedes
        item.sedes_options = sedes_options
        item
      elsif sedes
        # FIXME: lazy man's kwargs
        sedes_options.empty? ?
          sedes.deserialize(item) :
          sedes.deserialize(item, **sedes_options)
      else
        item
      end
    end

    ##
    # Read an item from an RLP string lazily.
    #
    # If the length prefix announces a string, the string is read; if it
    # announces a list, a {LazyList} is created.
    #
    # @param rlp [String] the rlp string to read from
    # @param start [Integer] the position at which to start reading
    #
    # @return [Array] A pair `[item, next_start]` where `item` is the read
    #   string or a {LazyList} and `next_start` is the position of the first
    #   unprocessed byte
    #
    def consume_item_lazy(rlp, start)
      t, l, s = consume_length_prefix(rlp, start)
      if t == :str
        consume_payload(rlp, s, :str, l)
      elsif t == :list
        [LazyList.new(rlp, s, s+l), s+l]
      else
        raise "Invalid item type: #{t}"
      end
    end

    ##
    # Get a specific element from an rlp encoded nested list.
    #
    # This method uses {RLP::DecodeLazy#decode_lazy} and, thus, decodes only
    # the necessary parts of the string.
    #
    # @example Usage
    #   rlpdata = RLP.encode([1, 2, [3, [4, 5]]])
    #   RLP.peek(rlpdata, 0, sedes: RLP::Sedes.big_endian_int) # => 1
    #   RLP.peek(rlpdata, [2, 0], sedes: RLP::Sedes.big_endian_int) # => 3
    #
    # @param rlp [String] the rlp string
    # @param index [Integer, Array] the index of the element to peek at (can be
    #   a list for nested data)
    # @param sedes [#deserialize] a sedes used to deserialize the peeked at
    #   object, or `nil` if no deserialization should be performed
    #
    # @raise [IndexError] if `index` is invalid (out of range or too many levels)
    #
    def peek(rlp, index, sedes: nil)
      ll = decode_lazy(rlp)
      index = Array(index)

      index.each do |i|
        raise IndexError, "Too many indices given" if primitive?(ll)
        ll = ll.fetch(i)
      end

      sedes ? sedes.deserialize(ll) : ll
    end
  end
end
