# frozen_string_literal: true

module Zen
  module Service::Plugins
    module ResultYielding
      extend Plugin

      module Extension
        def call
          return super unless block_given?

          result = nil
          super do
            result = yield
          end
          result
        end
      end

      def self.used(service_class)
        service_class.prepend(Extension)
      end
    end
  end
end
