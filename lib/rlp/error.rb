# -*- encoding : ascii-8bit -*-

module RLP
  module Error

    class RLPException < StandardError; end

    class EncodingError < RLPException
      attr :obj

      def initialize(message, obj)
        super(message)

        @obj = obj
      end
    end

    class DecodingError < RLPException
      attr :rlp

      def initialize(message, rlp)
        super(message)

        @rlp = rlp
      end
    end

    class SerializationError < RLPException
      attr :obj

      def initialize(message, obj)
        super(message)

        @obj = obj
      end
    end

    class DeserializationError < RLPException
      attr :serial

      def initialize(message, serial)
        super(message)

        @serial = serial
      end
    end

    class ListSerializationError < SerializationError
      attr :index, :element_exception

      def initialize(message: nil, obj: nil, element_exception: nil, index: nil)
        if message.nil?
          raise ArgumentError, "index and element_exception must be present" if index.nil? || element_exception.nil?
          message = "Serialization failed because of element at index #{index} ('#{element_exception}')"
        end

        super(message, obj)

        @index = index
        @element_exception = element_exception
      end
    end

    class ListDeserializationError < DeserializationError
      attr :index, :element_exception

      def initialize(message: nil, serial: nil, element_exception: nil, index: nil)
        if message.nil?
          raise ArgumentError, "index and element_exception must be present" if index.nil? || element_exception.nil?
          message = "Deserialization failed because of element at index #{index} ('#{element_exception}')"
        end

        super(message, serial)

        @index = index
        @element_exception = element_exception
      end
    end

    ##
    # Exception raised if serialization of a {RLP::Sedes::Serializable} object
    # fails.
    #
    class ObjectSerializationError < SerializationError
      attr :field, :list_exception

      ##
      # @param sedes [RLP::Sedes::Serializable] the sedes that failed
      # @param list_exception [RLP::Error::ListSerializationError] exception raised by the underlying
      #   list sedes, or `nil` if no exception has been raised
      #
      def initialize(message: nil, obj: nil, sedes: nil, list_exception: nil)
        if message.nil?
          raise ArgumentError, "list_exception and sedes must be present" if list_exception.nil? || sedes.nil?

          if list_exception.element_exception
            field = sedes.serializable_fields.keys[list_exception.index]
            message = "Serialization failed because of field #{field} ('#{list_exception.element_exception}')"
          else
            field = nil
            message = "Serialization failed because of underlying list ('#{list_exception}')"
          end
        else
          field = nil
        end

        super(message, obj)

        @field = field
        @list_exception = list_exception
      end
    end

    ##
    # Exception raised if deserialization by a {RLP::Sedes::Serializable} fails.
    #
    class ObjectDeserializationError < DeserializationError
      attr :sedes, :field, :list_exception

      ##
      # @param sedes [RLP::Sedes::Serializable] the sedes that failed
      # @param list_exception [RLP::ListDeserializationError] exception raised
      #   by the underlying list sedes, or `nil` if no such exception has been
      #   raised
      #
      def initialize(message: nil, serial: nil, sedes: nil, list_exception: nil)
        if message.nil?
          raise ArgumentError, "list_exception must be present" if list_exception.nil?

          if list_exception.element_exception
            raise ArgumentError, "sedes must be present" if sedes.nil?

            field = sedes.serializable_fields.keys[list_exception.index]
            message = "Deserialization failed because of field #{field} ('#{list_exception.element_exception}')"
          else
            field = nil
            message = "Deserialization failed because of underlying list ('#{list_exception}')"
          end
        end

        super(message, serial)

        @sedes = sedes
        @field = field
        @list_exception = list_exception
      end
    end

  end
end
