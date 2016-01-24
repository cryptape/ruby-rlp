require_relative 'sedes/big_endian_int'
require_relative 'sedes/binary'
require_relative 'sedes/list'
require_relative 'sedes/countable_list'

module RLP
  module Sedes

    class <<self
      def infer(obj)
        return obj if sedes?(obj)
        return big_endian_int if obj.is_a?(Integer) && obj >= 0
        return binary if Binary.valid_type?(obj)
        return List.new(elements: obj.map {|item| infer(item) }) if RLP.list?(obj)

        msg = "Did not find sedes handling type %s" % obj.class.name
        raise ArgumentError, msg
      end

      def sedes?(obj)
        obj.respond_to?(:serialize) && obj.respond_to?(:deserialize)
      end

      def big_endian_int
        @big_endian_int ||= BigEndianInt.new
      end

      def binary
        @binary ||= Binary.new
      end
    end

  end
end
