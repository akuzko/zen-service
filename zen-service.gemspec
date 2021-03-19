# frozen_string_literal: true

require_relative "lib/zen/service/version"

Gem::Specification.new do |spec|
  spec.name          = "zen-service"
  spec.version       = Zen::Service::VERSION
  spec.authors       = ["Artem Kuzko"]
  spec.email         = ["a.kuzko@gmail.com"]

  spec.summary       = "Flexible and highly extensible Services for business logic organization"
  spec.description   = "Flexible and highly extensible Services for business logic organization"
  spec.homepage      = "https://github.com/akuzko/zen-service"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org/"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/akuzko/zen-service.git"
  spec.metadata["changelog_uri"] = "https://github.com/akuzko/zen-service/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
