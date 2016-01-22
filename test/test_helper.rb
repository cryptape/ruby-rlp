require 'minitest/autorun'
require 'rlp'
require 'json'

##################
# Helper Methods #
##################

def to_bytes(v)
  if v.instance_of?(String)
    RLP.str_to_bytes(v)
  elsif v.instance_of?(Array)
    v.map {|item| to_bytes(item) }
  else
    v
  end
end

def code_array_to_bytes(code_array)
  code_array.pack('C*')
end

def load_json_fixtures(path)
  File.open(path, 'r') {|f| JSON.load f }
end
