module RLP
  module Utils
    def bytes_to_str(v)
      v.unpack('U*').pack('U*')
    end

    def str_to_bytes(v)
      v.dup.force_encoding('ascii-8bit')
    end

    def int_to_big_endian(v)
      hex = v.to_s(16)
      hex = "0#{hex}" if hex.size.odd?
      [hex].pack('H*')
    end

    def encode_hex(b)
      raise ArgumentError, "Value must be an instance of String"  unless b.instance_of?(String)
      b = str_to_bytes(b) unless b.encoding.name == 'ASCII-8BIT'
      b.unpack("H*").first
    end
  end
end
