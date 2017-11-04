require 'rspec/its'
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'excom'
require 'pry'

module SpecHelper
  module GroupMethods
    def Kommand(&block)
      let(:kommand_class) { Class.new(Excom::Command, &block) }
    end

    def Sentry(&block)
      before do
        Object.send(:remove_const, :SpecSentry) if defined? SpecSentry

        sentry = Class.new(Excom::Sentry, &block)
        Object.const_set(:SpecSentry, sentry)
      end
    end
  end

  module ExampleMethods
    def Kommand(*args)
      kommand_class.new(*args)
    end
  end
end

RSpec.configure do |config|
  config.extend SpecHelper::GroupMethods
  config.include SpecHelper::ExampleMethods
end
