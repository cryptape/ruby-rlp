# -*- encoding : ascii-8bit -*-
require 'test_helper'

class SerializableSedesTest < Minitest::Test
  include RLP

  class Test1
    include RLP::Sedes::Serializable

    set_serializable_fields(
      field1: RLP::Sedes.big_endian_int,
      field2: RLP::Sedes.binary,
      field3: RLP::Sedes::List.new(elements: [
        RLP::Sedes.big_endian_int,
        RLP::Sedes.binary
      ])
    )
  end

  class Test2
    include RLP::Sedes::Serializable

    set_serializable_fields(
      field1: Test1,
      field2: RLP::Sedes::List.new(elements: [Test1, Test1])
    )
  end

  def test_serializable
    t1a_data = [5, 'a', [0, '']]
    t1b_data = [9, 'b', [2, '']]

    t1a = Test1.new *t1a_data
    t1b = Test1.new *t1b_data
    t2  = Test2.new t1a, [t1a, t1b]

    # equality
    assert t1a == t1a
    assert t1b == t1b
    assert t2  == t2
    assert t1a != t1b
    assert t1b != t2
    assert t2  != t1a

    # mutability
    t1a.field1 += 1
    t1a.field2 = 'x'
    assert 6, t1a.field1
    assert 'x', t1a.field2

    t1a.field1 -= 1
    t1a.field2 = 'a'
    assert 5, t1a.field1
    assert 'a', t1a.field2

    # inference
    assert_equal Test1, Sedes.infer(t1a)
    assert_equal Test1, Sedes.infer(t1b)
    assert_equal Test2, Sedes.infer(t2)

    # serialization
    assert_raises(SerializationError) { Test1.serialize(t2) }
    assert_raises(SerializationError) { Test2.serialize(t1a) }
    assert_raises(SerializationError) { Test2.serialize(t1b) }

    t1a_s = Test1.serialize t1a
    t1b_s = Test1.serialize t1b
    t2_s  = Test2.serialize t2
    assert_equal ["\x05", "a", ["", ""]], t1a_s
    assert_equal ["\x09", "b", ["\x02", ""]], t1b_s
    assert_equal [t1a_s, [t1a_s, t1b_s]], t2_s

    # deserialization
    t1a_d = Test1.deserialize t1a_s
    t1b_d = Test1.deserialize t1b_s
    t2_d  = Test2.deserialize t2_s
    assert_equal false, t1a_d.mutable?
    assert_equal false, t1b_d.mutable?
    assert_equal false, t2_d.mutable?

    [t1a_d, t1b_d].each do |obj|
      before1 = obj.field1
      before2 = obj.field2
      assert_raises(ArgumentError) { obj.field1 += 1 }
      assert_raises(ArgumentError) { obj.field2 = 'x' }
      assert_equal before1, obj.field1
      assert_equal before2, obj.field2
    end

    assert_equal t1a, t1a_d
    assert_equal t1b, t1b_d
    assert_equal t2,  t2_d

    # encoding and decoding
    [t1a, t1b, t2].each do |obj|
      rlp_code = encode obj

      assert_nil obj._cached_rlp
      assert_equal true, obj.mutable?

      assert_equal rlp_code, encode(obj, cache: true)
      assert_equal rlp_code, obj._cached_rlp
      assert_equal false, obj.mutable?

      assert_equal rlp_code, encode(obj)
      assert_equal rlp_code, obj._cached_rlp
      assert_equal false, obj.mutable?

      obj_decoded = decode rlp_code, sedes: obj.class
      assert_equal obj, obj_decoded
      assert_equal false, obj_decoded.mutable?
      assert_equal rlp_code, obj_decoded._cached_rlp
    end
  end

  def test_make_immutable
    list_m = []
    list_i = RLP::Utils.make_immutable! list_m
    assert list_m.object_id != list_i.object_id

    assert_equal 1, RLP::Utils.make_immutable!(1)
    assert_equal 'a', RLP::Utils.make_immutable!('a')
    assert_equal [1,2,3], RLP::Utils.make_immutable!([1,2,3])
    assert_equal [1,2,'a'], RLP::Utils.make_immutable!([1,2,'a'])
    assert_equal [[1],[2,[3],4],5,6], RLP::Utils.make_immutable!([[1], [2,[3],4],5,6])

    t1a_data = [5, 'a', [0, '']]
    t1b_data = [9, 'b', [2, '']]

    t1a = Test1.new *t1a_data
    t1b = Test1.new *t1b_data
    t2  = Test2.new t1a, [t1a, t1b]

    assert_equal true, t2.mutable?
    assert_equal true, t2.field1.mutable?
    assert_equal true, t2.field2[0].mutable?
    assert_equal true, t2.field2[1].mutable?

    t2.make_immutable!
    assert_equal false, t2.mutable?
    assert_equal false, t1a.mutable?
    assert_equal false, t1b.mutable?
    assert_equal t1a, t2.field1
    assert_equal [t1a, t1b], t2.field2

    t1a = Test1.new *t1a_data
    t1b = Test1.new *t1b_data
    t2  = Test2.new t1a, [t1a, t1b]

    assert_equal true, t2.mutable?
    assert_equal true, t2.field1.mutable?
    assert_equal true, t2.field2[0].mutable?
    assert_equal true, t2.field2[1].mutable?

    assert_equal [t1a, [t2, t1b]], RLP::Utils.make_immutable!([t1a, [t2, t1b]])

    assert_equal false, t2.mutable?
    assert_equal false, t1a.mutable?
    assert_equal false, t1b.mutable?
  end

  def test_create_new_sedes_excluding_some_fields
    cls = Test1.exclude [:field2]
    assert_equal Test1, cls.superclass
    assert_equal %i(field1 field3), cls.serializable_fields.keys
    assert_equal %i(field1 field2 field3), Test1.serializable_fields.keys
  end

  class Test3
    include RLP::Sedes::Serializable

    set_serializable_fields(
      field1: RLP::Sedes.big_endian_int
    )

    attr :bar

    def initialize(*args)
      field1 = args[0] if args[0].is_a?(Integer)
      options = args.last.instance_of?(Hash) ? args.last : {}

      field1 = options.delete(:field1) if options.has_key?(:field1)
      bar = options.delete(:bar) || 1

      @bar = bar
      super(field1)
    end
  end

  def test_deserialize_with_extra_arguments
    t = Test3.new(1, bar: 2)
    assert_equal 1, t.field1
    assert_equal 2, RLP.decode(RLP.encode(t), sedes: Test3, bar: 2).bar
  end

  class Test4 < Test1
    add_serializable_field :field4, RLP::Sedes.big_endian_int
    add_serializable_field :field5, RLP::Sedes.big_endian_int
  end

  def test_inherit
    assert_equal %i(field1 field2 field3 field4 field5), Test4.serializable_fields.keys
  end

  def test_initialize_error_message
    t1a_data = [5, 'a', ]

    assert_raises "Not all fields initialized. Missing: [:field3]" do
      t1a = Test1.new(*t1a_data)
      Test1.serialize(t1a)
    end
  end

end
