require 'rspec/its'
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'excom'
require 'pry'

module SpecHelper
  module GroupMethods
    def def_service(&block)
      let(:service_class) { Class.new(Excom::Service, &block) }
    end

    def def_sentry(&block)
      before do
        Object.send(:remove_const, :SpecSentry) if defined? SpecSentry

        sentry = Class.new(Excom::Sentry, &block)
        Object.const_set(:SpecSentry, sentry)
      end
    end
  end

  module ExampleMethods
    def build_service(*args)
      service_class.new(*args)
    end
  end
end

RSpec.configure do |config|
  config.extend SpecHelper::GroupMethods
  config.include SpecHelper::ExampleMethods
end
