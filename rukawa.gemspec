# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rukawa/version'

Gem::Specification.new do |spec|
  spec.name          = "rukawa"
  spec.version       = Rukawa::VERSION
  spec.authors       = ["joker1007"]
  spec.email         = ["kakyoin.hierophant@gmail.com"]

  spec.summary       = %q{Hyper simple job workflow engine}
  spec.description   = %q{Hyper simple job workflow engine}
  spec.homepage      = "https://github.com/joker1007/rukawa"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "concurrent-ruby"
  spec.add_runtime_dependency "thor"
  spec.add_runtime_dependency "terminal-table"
  spec.add_runtime_dependency "paint"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-power_assert"
end
