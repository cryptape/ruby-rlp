# -*- encoding : ascii-8bit -*-

module RLP
  module Sedes
    ##
    # A sedes for lists of arbitrary length.
    #
    class CountableList
      include Error
      include Utils

      def initialize(element_sedes, max_length: nil)
        @element_sedes = element_sedes
        @max_length = max_length
      end

      def serialize(obj)
        raise ListSerializationError.new(message: "Can only serialize sequences", obj: obj) unless list?(obj)

        result = []
        obj.each_with_index do |e, i|
          begin
            result.push @element_sedes.serialize(e)
          rescue SerializationError => e
            raise ListSerializationError.new(obj: obj, element_exception: e, index: i)
          end

          if @max_length && result.size > @max_length
            msg = "Too many elements (#{result.size}, allowed #{@max_length})"
            raise ListSerializationError.new(message: msg, obj: obj)
          end
        end

        result
      end

      def deserialize(serial)
        raise ListDeserializationError.new(message: 'Can only deserialize sequences', serial: serial) unless list?(serial)

        result = []
        serial.each_with_index do |e, i|
          begin
            result.push @element_sedes.deserialize(e)
          rescue DeserializationError => e
            raise ListDeserializationError.new(serial: serial, element_exception: e, index: i)
          end

          if @max_length && result.size > @max_length
            msg = "Too many elements (#{result.size}, allowed #{@max_length})"
            raise ListDeserializationError.new(message: msg, serial: serial)
          end
        end

        result.freeze
      end

    end
  end
end
