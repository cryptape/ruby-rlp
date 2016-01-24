module RLP
  module Utils
    def primitive?(item)
      item.instance_of?(String)
    end

    def list?(item)
      item.respond_to?(:each)
    end

    def bytes_to_str(v)
      v.unpack('U*').pack('U*')
    end

    def str_to_bytes(v)
      v.dup.force_encoding('ascii-8bit')
    end

    def big_endian_to_int(v)
      v.unpack('H*').first.to_i(16)
    end

    def int_to_big_endian(v)
      hex = v.to_s(16)
      hex = "0#{hex}" if hex.size.odd?
      [hex].pack('H*')
    end

    def encode_hex(b)
      raise TypeError, "Value must be an instance of String" unless b.instance_of?(String)
      b = str_to_bytes(b) unless b.encoding.name == 'ASCII-8BIT'
      b.unpack("H*").first
    end
  end
end
