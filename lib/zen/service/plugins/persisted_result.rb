# frozen_string_literal: true

module Zen
  module Service::Plugins
    module PersistedResult
      extend Plugin

      module Extension
        def call
          @result = super
        end
      end

      attr_reader :result

      def initialize(*, **)
        super
        extend(Extension)
      end

      def called?
        defined?(@result)
      end
    end
  end
end
