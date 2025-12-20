# frozen_string_literal: true

module Zen
  module Service::Plugins
    module PersistedResult
      extend Plugin

      default_options call_unless_called: false

      module Extension
        def call
          @result = super
        end
      end

      def initialize(*, **)
        super
        extend(Extension)
      end

      def called?
        defined?(@result)
      end

      def result
        call if self.class.plugins[:persisted_result].options[:call_unless_called] && !called?

        @result
      end
    end
  end
end
