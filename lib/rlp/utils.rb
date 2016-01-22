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
  end
end
