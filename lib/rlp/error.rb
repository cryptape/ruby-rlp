module RLP
  module Error

    class RLPException < Exception; end

    class EncodingError < RLPException
      def initialize(message, obj)
        super(message)

        @obj = obj
      end
    end

    class DecodingError < RLPException
      def initialize(message, rlp)
        super(message)

        @rlp = rlp
      end
    end

    class SerializationError < RLPException
      def initialize(message, obj)
        super(message)

        @obj = obj
      end
    end

    class ListSerializationError < SerializationError
      def initialize(message: nil, obj: nil, element_exception: nil, index: nil)
        if message.nil?
          raise ArgumentError, "index and element_exception must be present" if index.nil? || element_exception.nil?
          message = 'Serialization failed because of element at index %s ("%s")' % [index, element_exception]
        end

        super(message, obj)

        @index = index
        @element_exception = element_exception
      end
    end

  end
end
