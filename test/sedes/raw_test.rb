require 'test_helper'

class RawSedesTest < Minitest::Test
  include RLP

  def test_raw_sedes
    [
      '',
      'asdf',
      'fds89032#$@%',
      'dfsa',
      ['dfsa', ''],
      [],
      ['fdsa', ['dfs', ['jfdkl']]]
    ].each do |s|
      Sedes.raw.serialize(s)
      code = encode(s, sedes: Sedes.raw)
      assert_equal s, decode(code, sedes: Sedes.raw)
    end

    [
      0,
      32,
      ['asdf', ['fdsa', [5]]],
      String
    ].each do |n|
      assert_raises(SerializationError) { Sedes.raw.serialize(n) }
    end
  end
end
