# frozen_string_literal: true

module Zen
  module Service::Plugins
    module Callable
      extend Plugin

      def call(&)
        # No-op by default
      end

      module ClassMethods
        def call(*args, **kwargs, &block)
          new(*args, **kwargs).call(&block)
        end
        alias [] call
      end
    end
  end
end
