# frozen_string_literal: true

module Zen
  class Service
    class Callable
      extend Plugins::Pluggable

      use :callable
    end
  end
end
