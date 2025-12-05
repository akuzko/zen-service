# frozen_string_literal: true

require_relative "service/version"
require_relative "service/plugins"

module Zen
  class Service
    autoload :SpecHelpers, "zen/service/spec_helpers"

    extend Plugins::Pluggable

    use :callable
    use :attributes
  end
end
