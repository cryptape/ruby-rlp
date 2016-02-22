# -*- encoding : ascii-8bit -*-

module RLP
  module Sedes
    ##
    # A sedes for lists of fixed length
    #
    class List < Array
      include Error
      include Utils

      def initialize(elements: [], strict: true)
        super()

        @strict = strict

        elements.each do |e|
          if Sedes.sedes?(e)
            push e
          elsif list?(e)
            push List.new(elements: e)
          else
            raise TypeError, "Instances of List must only contain sedes objects or nested sequences thereof."
          end
        end
      end

      def serialize(obj)
        raise ListSerializationError.new(message: "Can only serialize sequences", obj: obj) unless list?(obj)
        raise ListSerializationError.new(message: "List has wrong length", obj: obj) if (@strict && self.size != obj.size) || self.size < obj.size

        result = []
        obj.zip(self).each_with_index do |(element, sedes), i|
          begin
            result.push sedes.serialize(element)
          rescue SerializationError => e
            raise ListSerializationError.new(obj: obj, element_exception: e, index: i)
          end
        end

        result
      end

      def deserialize(serial)
        raise ListDeserializationError.new(message: 'Can only deserialize sequences', serial: serial) unless list?(serial)
        raise ListDeserializationError.new(message: 'List has wrong length', serial: serial) if @strict && serial.size != self.size

        result = []

        len = [serial.size, self.size].min
        len.times do |i|
          begin
            sedes = self[i]
            element = serial[i]
            result.push sedes.deserialize(element)
          rescue DeserializationError => e
            raise ListDeserializationError.new(serial: serial, element_exception: e, index: i)
          end
        end

        result.freeze
      end
    end
  end
end
