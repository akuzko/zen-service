require "excom/version"

module Excom
  autoload :Plugins, 'excom/plugins'
  autoload :Service, 'excom/service'

  extend Plugins::Context::ExcomMethods
end
