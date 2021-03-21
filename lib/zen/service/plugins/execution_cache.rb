# frozen_string_literal: true

module Zen
  module Service::Plugins
    module ExecutionCache
      extend Plugin

      def initialize(*)
        super
        extend Extension
      end

      module Extension
        def execute(*)
          return super if block_given? || !executed?

          self
        end
      end
    end
  end
end
