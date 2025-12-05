# frozen_string_literal: true

require "ostruct"

module Zen
  module Service::Plugins
    module Callable
      extend Plugin

      def call
        # No-op by default
      end

      module ClassMethods
        def call(...)
          new(...).call
        end
        alias [] call
      end
    end
  end
end
