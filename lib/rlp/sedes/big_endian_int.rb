# -*- encoding : ascii-8bit -*-

module RLP
  module Sedes
    class BigEndianInt
      include Constant
      include Error
      include Utils

      def initialize(size=nil)
        @size = size
      end

      def serialize(obj)
        raise SerializationError.new("Can only serialize integers", obj) unless obj.is_a?(Integer)
        raise SerializationError.new("Cannot serialize negative integers", obj) if obj < 0

        if @size && obj >= 256**@size
          msg = "Integer too large (does not fit in #{@size} bytes)"
          raise SerializationError.new(msg, obj)
        end

        s = obj == 0 ? BYTE_EMPTY : int_to_big_endian(obj)

        @size ? "#{BYTE_ZERO * [0, @size-s.size].max}#{s}" : s
      end

      def deserialize(serial)
        raise DeserializationError.new("Invalid serialization (wrong size)", serial) if @size && serial.size != @size
        raise DeserializationError.new("Invalid serialization (not minimal length)", serial) if !@size && serial.size > 0 && serial[0] == BYTE_ZERO

        serial = serial || BYTE_ZERO
        big_endian_to_int(serial)
      end

    end
  end
end
