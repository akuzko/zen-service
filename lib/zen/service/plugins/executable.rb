# frozen_string_literal: true

require "ostruct"

module Zen
  module Service::Plugins
    module Executable
      extend Plugin

      attr_reader :result

      def execute(&)
        @result = call(&)
        self
      end

      def executed?
        defined?(@result)
      end
    end
  end
end
