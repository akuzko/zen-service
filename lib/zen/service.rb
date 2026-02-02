# frozen_string_literal: true

require_relative "service/version"
require_relative "service/plugins"
require_relative "service/callable"

module Zen
  class Service
    extend Plugins::Pluggable

    use :callable
    use :attributes
  end
end
