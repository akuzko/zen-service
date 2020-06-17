require "excom/version"

module Excom
  autoload :Plugins, 'excom/plugins'
  autoload :Service, 'excom/service'

  extend Plugins::Context::ExcomMethods

  UNDEFINED = Object.new.tap do |obj|
    def obj.to_s
      'UNDEFINED'.freeze
    end

    def obj.inspect
      'UNDEFINED'.freeze
    end

    obj.freeze
  end
end
