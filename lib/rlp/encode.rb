# -*- encoding : ascii-8bit -*-

module RLP
  module Encode
    include Constant
    include Error
    include Utils

    ##
    # Encode a Ruby object in RLP format.
    #
    # By default, the object is serialized in a suitable way first (using
    # {RLP::Sedes.infer}) and then encoded. Serialization can be explicitly
    # suppressed by setting {RLP::Sedes.infer} to `false` and not passing an
    # alternative as `sedes`.
    #
    # If `obj` has an attribute `_cached_rlp` (as, notably,
    # {RLP::Serializable}) and its value is not `nil`, this value is returned
    # bypassing serialization and encoding, unless `sedes` is given (as the
    # cache is assumed to refer to the standard serialization which can be
    # replaced by specifying `sedes`).
    #
    # If `obj` is a {RLP::Serializable} and `cache` is true, the result of the
    # encoding will be stored in `_cached_rlp` if it is empty and
    # {RLP::Serializable.make_immutable} will be invoked on `obj`.
    #
    # @param obj [Object] object to encode
    # @param sedes [#serialize(obj)] an object implementing a function
    #   `serialize(obj)` which will be used to serialize `obj` before
    #   encoding, or `nil` to use the infered one (if any)
    # @param infer_serializer [Boolean] if `true` an appropriate serializer
    #   will be selected using {RLP::Sedes.infer} to serialize `obj` before
    #   encoding
    # @param cache [Boolean] cache the return value in `obj._cached_rlp` if
    #   possible and make `obj` immutable (default `false`)
    #
    # @return [String] the RLP encoded item
    #
    # @raise [RLP::EncodingError] in the rather unlikely case that the item
    #   is too big to encode (will not happen)
    # @raise [RLP::SerializationError] if the serialization fails
    #
    def encode(obj, sedes: nil, infer_serializer: true, cache: false)
      return obj._cached_rlp if obj.is_a?(Sedes::Serializable) && obj._cached_rlp && sedes.nil?

      really_cache = obj.is_a?(Sedes::Serializable) && sedes.nil? && cache

      if sedes
        item = sedes.serialize(obj)
      elsif infer_serializer
        item = Sedes.infer(obj).serialize(obj)
      else
        item = obj
      end

      result = encode_raw(item)

      if really_cache
        obj._cached_rlp = result
        obj.make_immutable!
      end

      result
    end

    private

    def encode_raw(item)
      return item if item.instance_of?(RLP::Data)
      return encode_primitive(item) if primitive?(item)
      return encode_list(item) if list?(item)

      msg = "Cannot encode object of type #{item.class.name}"
      raise EncodingError.new(msg, item)
    end

    def encode_primitive(item)
      return str_to_bytes(item) if item.size == 1 && item.ord < PRIMITIVE_PREFIX_OFFSET

      payload = str_to_bytes item
      prefix = length_prefix payload.size, PRIMITIVE_PREFIX_OFFSET

      "#{prefix}#{payload}"
    end

    def encode_list(list)
      payload = list.map {|item| encode_raw(item) }.join
      prefix = length_prefix payload.size, LIST_PREFIX_OFFSET

      "#{prefix}#{payload}"
    end

    def length_prefix(length, offset)
      if length < SHORT_LENGTH_LIMIT
        (offset+length).chr
      elsif length < LONG_LENGTH_LIMIT
        length_string = int_to_big_endian(length)
        length_len = (offset + SHORT_LENGTH_LIMIT - 1 + length_string.size).chr
        "#{length_len}#{length_string}"
      else
        raise ArgumentError, "Length greater than 256**8"
      end
    end
  end
end
