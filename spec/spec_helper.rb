# frozen_string_literal: true

require "zen/service"
require "pry"
require "rspec/its"

module SpecHelper
  def self.included(target)
    target.extend(ClassMethods)
  end

  def build_service(*args)
    service_class.new(*args)
  end

  module ClassMethods
    def def_service(&block)
      let(:service_class) { Class.new(Zen::Service, &block) }
    end
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include SpecHelper
  config.include Zen::Service::SpecHelpers
end
