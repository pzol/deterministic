# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'deterministic/version'

Gem::Specification.new do |spec|
  spec.name          = "deterministic"
  spec.version       = Deterministic::VERSION
  spec.authors       = ["Piotr Zolnierek"]
  spec.email         = ["pz@anixe.pl"]
  spec.description   = %q{A gem providing failsafe flow}
  spec.summary       = %q{see above}
  spec.homepage      = "http://github.com/pzol/deterministic"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 3"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-bundler"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "simplecov"
end
