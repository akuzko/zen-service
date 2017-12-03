# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'excom/version'

Gem::Specification.new do |spec|
  spec.name          = "excom"
  spec.version       = Excom::VERSION
  spec.authors       = ["Artem Kuzko"]
  spec.email         = ["a.kuzko@gmail.com"]

  spec.summary       = %q{Flexible and highly extensible Commands (Service Objects) for business logic}
  spec.description   = %q{Flexible and highly extensible Commands (Service Objects) for business logic}
  spec.homepage      = "https://github.com/akuzko/excom"
  spec.license       = "MIT"

  spec.required_ruby_version = '>= 2.2.0'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-its", "~> 1.2"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-nav"
end
