require "excom/version"

module Excom
  autoload :Plugins, 'excom/plugins'
  autoload :Command, 'excom/command'

  extend Plugins::Context::ExcomMethods

  Sentry = Plugins::Sentry::Sentinel

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
