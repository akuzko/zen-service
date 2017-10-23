require "excom/version"

module Excom
  autoload :Plugins, 'excom/plugins'
  autoload :Command, 'excom/command'

  extend Plugins::Context::Global

  Sentry = Plugins::Sentry::Sentinel
end
