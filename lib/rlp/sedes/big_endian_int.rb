module RLP
  module Sedes
    class BigEndianInt
      include RLP::Utils

      ZERO = "\x00".force_encoding('ascii-8bit').freeze
      EMPTY = ''.force_encoding('ascii-8bit').freeze

      def initialize(size: nil)
        @size = size
      end

      def serialize(obj)
        raise ArgumentError, "Can only serialize integers" unless obj.is_a?(Integer)
        raise ArgumentError, "Cannot serialize negative integers" if obj < 0

        if @size && obj >= 256**@size
          msg = "Integer too large (does not fit in %s bytes)" % @size
          raise ArgumentError, msg
        end

        s = obj == 0 ? ZERO : int_to_big_endian(obj)

        @size ? "#{ZERO * [0, @size-s.size].max}#{s}" : s
      end

      def deserialize(serial)
        raise ArgumentError, "Invalid serialization (wrong size)" if @size && serial.size != @size
        raise ArgumentError, "Invalid serialization (not minimal length)" if !@size && serial.size > 0 && serial[0] == ZERO

        serial = serial || ZERO
        big_endian_to_int(serial)
      end

    end
  end
end
