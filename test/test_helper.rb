require 'minitest/autorun'

##################
# Helper Methods #
##################

def code_array_to_bytes(code_array)
  code_array.pack('C*')
end
