$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rlp/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rlp"
  s.version     = RLP::VERSION
  s.authors     = ["Jan Xie"]
  s.email       = ["jan.h.xie@gmail.com"]
  s.homepage    = "https://github.com/janx/ruby-rlp"
  s.summary     = "The ruby RLP serialization library."
  s.description = "A Ruby implementation of Ethereum's Recursive Length Prefix encoding (RLP)."
  s.license     = 'MIT'

  s.files = Dir["{lib}/**/*"] + ["LICENSE", "README.md"]
end
