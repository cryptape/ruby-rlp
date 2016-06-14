# -*- encoding : ascii-8bit -*-

module RLP
  module Sedes
    ##
    # Mixin for objects which can be serialized into RLP lists.
    #
    # `fields` defines which attributes are serialized and how this is done. It
    # is expected to be a hash in the form of `name => sedes`. Here, `name` is
    # the name of an attribute and `sedes` is the sedes object that will be used
    # to serialize the corresponding attribute. The object as a whole is then
    # serialized as a list of those fields.
    #
    module Serializable

      module ClassMethods
        include Error

        def set_serializable_fields(fields)
          raise "Cannot override serializable fields!" if @serializable_fields
          @serializable_fields = {} # always reset
          fields.each {|name, sedes| add_serializable_field name, sedes }
        end

        def add_serializable_field(name, sedes)
          unless @serializable_fields
            # append or reset
            @serializable_fields = superclass.include?(Sedes::Serializable) ? superclass.serializable_fields.dup : {}
          end

          @serializable_fields[name] = sedes

          class_eval <<-ATTR
            def #{name}
              @#{name}
            end

            def #{name}=(v)
              _set_field(:#{name}, v)
            end
          ATTR
        end

        def inherit_serializable_fields!
          @serializable_fields = superclass.serializable_fields
        end

        def serializable_fields
          @serializable_fields
        end

        def serializable_sedes
          @serializable_sedes ||= Sedes::List.new(elements: serializable_fields.values)
        end

        def serialize(obj)
          begin
            field_values = serializable_fields.keys.map {|k| obj.send k }
          rescue NoMethodError => e
            raise ObjectSerializationError.new(message: "Cannot serialize this object (missing attribute)", obj: obj)
          end

          begin
            serializable_sedes.serialize(field_values)
          rescue ListSerializationError => e
            raise ObjectSerializationError.new(obj: obj, sedes: self, list_exception: e)
          end
        end

        def deserialize(serial, **options)
          exclude = options.delete(:exclude)

          begin
            values = serializable_sedes.deserialize(serial)
          rescue ListDeserializationError => e
            raise ObjectDeserializationError.new(serial: serial, sedes: self, list_exception: e)
          end

          params = Hash[*serializable_fields.keys.zip(values).flatten(1)]
          params.delete_if {|field, value| exclude.include?(field) } if exclude

          obj = self.new params.merge(options)
          obj.instance_variable_set :@_mutable, false
          obj
        end

        ##
        # Create a new sedes considering only a reduced set of fields.
        #
        def exclude(excluded_fields)
          fields = serializable_fields.dup.delete_if {|k, v| excluded_fields.include?(k) }
          Class.new(self).tap {|cls| cls.set_serializable_fields fields }
        end
      end

      class <<self
        def included(base)
          base.extend ClassMethods
        end
      end

      attr_accessor :_cached_rlp

      def initialize(*args)
        serializable_initialize parse_field_args(args)
      end

      ##
      # Mimic python's argument syntax, accept both normal arguments and named
      # arguments. Normal argument overrides named argument.
      #
      def parse_field_args(args)
        h = {}

        options = args.last.is_a?(Hash) ? args.pop : {}
        field_set = self.class.serializable_fields.keys

        fields = self.class.serializable_fields.keys[0,args.size]
        fields.zip(args).each do |(field, arg)|
          h[field] = arg
          field_set.delete field
        end

        options.each do |field, value|
          if field_set.include?(field)
            h[field] = value
            field_set.delete field
          end
        end

        h
      end

      def serializable_initialize(fields)
        make_mutable!

        field_set = self.class.serializable_fields.keys
        fields.each do |field, value|
          _set_field field, value
          field_set.delete field
        end

        raise TypeError, "Not all fields initialized" unless field_set.size == 0
      end

      def _set_field(field, value)
        make_mutable! unless instance_variable_defined?(:@_mutable)

        if mutable? || !self.class.serializable_fields.has_key?(field)
          instance_variable_set :"@#{field}", value
        else
          raise ArgumentError, "Tried to mutate immutable object"
        end
      end

      def ==(other)
        return false unless other.class.respond_to?(:serialize)
        self.class.serialize(self) == other.class.serialize(other)
      end

      def mutable?
        @_mutable
      end

      def make_immutable!
        make_mutable!
        self.class.serializable_fields.keys.each do |field|
          ::RLP::Utils.make_immutable! send(field)
        end

        @_mutable = false
        self
      end

      def make_mutable!
        @_mutable = true
      end

    end
  end
end
