require 'rlp/constant'
require 'rlp/data'
require 'rlp/utils'

module RLP
  include Constant
  include Utils

  extend self

  def encode(obj, sedes: nil, infer_serializer: true, cache: false)
    # TODO: cache flow

    if sedes
      # TODO: customize sedes flow
      #item = sedes.serialize(obj)
    elsif infer_serializer
      # TODO: infer serializer
      #item = infer_sedes(obj).serialize(obj)
      item = obj
    else
      item = obj
    end

    result = encode_raw(item)
    result
  end

  def encode_raw(item)
    return item if item.instance_of?(RLP::Data)
    return encode_primitive(item) if primitive?(item)
    return encode_list(item) if list?(item)

    msg = "Cannot encode object of type %s" % item.class.name
    raise ArgumentError, msg
  end

  def primitive?(item)
    item.instance_of?(String)
  end

  def list?(item)
    item.respond_to?(:each)
  end

  def encode_primitive(item)
    return str_to_bytes(item) if item.size == 1 && item.ord < 0x80

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
