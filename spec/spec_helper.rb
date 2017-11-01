require 'rspec/its'
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'excom'
require 'pry'

module SpecHelper
  module GroupMethods
    def Kommand(&block)
      let(:kommand_class) { Class.new(Excom::Command, &block) }
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
