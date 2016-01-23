module RLP
  module Sedes
    class Binary
      include RLP::Utils

      Infinity = 1.0 / 0.0

      class <<self
        def valid_type?(obj)
          obj.instance_of?(String)
        end
      end

      def initialize(min_length: 0, max_length: Infinity, allow_empty: false)
        @min_length = min_length
        @max_length = max_length
        @allow_empty = allow_empty
      end

      def serialize(obj)
        raise SerializationError.new("Object is not a serializable (%s)" % obj.class, obj) unless self.class.valid_type?(obj)

        serial = str_to_bytes obj
        raise SerializationError.new("Object has invalid length", serial) unless valid_length?(serial.size)

        serial
      end

      def deserialize(serial)
        raise DeserializationError.new("Objects of type %s cannot be deserialized" % serial.class, serial) unless primitive?(serial)
        raise DeserializationError.new("%s has invalid length" % serial.class, serial) unless valid_length?(serial.size)

        serial
      end

      private

      def valid_length?(len)
        (@min_length <= len && len <= @max_length) ||
          (@allow_empty && len == 0)
      end

    end
  end
end
