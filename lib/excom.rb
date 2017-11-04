require "excom/version"

module Excom
  autoload :Plugins, 'excom/plugins'
  autoload :Command, 'excom/command'

  extend Plugins::Context::ExcomMethods

  Sentry = Plugins::Sentry::Sentinel
end
