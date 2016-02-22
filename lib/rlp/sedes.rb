# -*- encoding : ascii-8bit -*-

require_relative 'sedes/big_endian_int'
require_relative 'sedes/binary'
require_relative 'sedes/list'
require_relative 'sedes/countable_list'
require_relative 'sedes/raw'
require_relative 'sedes/serializable'

module RLP
  module Sedes

    class <<self
      ##
      # Try to find a sedes objects suitable for a given Ruby object.
      #
      # The sedes objects considered are `obj`'s class, `big_endian_int` and
      # `binary`. If `obj` is a list, a `RLP::Sedes::List` will be constructed
      # recursively.
      #
      # @param obj [Object] the Ruby object for which to find a sedes object
      #
      # @raise [TypeError] if no appropriate sedes could be found
      #
      def infer(obj)
        return obj.class if sedes?(obj.class)
        return big_endian_int if obj.is_a?(Integer) && obj >= 0
        return binary if Binary.valid_type?(obj)
        return List.new(elements: obj.map {|item| infer(item) }) if RLP.list?(obj)

        raise TypeError, "Did not find sedes handling type #{obj.class.name}"
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

      def raw
        @raw ||= Raw.new
      end
    end

  end
end
