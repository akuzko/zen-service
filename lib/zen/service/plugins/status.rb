# frozen_string_literal: true

module Zen
  module Service::Plugins
    module Status
      extend Plugin

      default_options(success: [], failure: [])

      def self.used(service_class, **)
        service_class.add_execution_prop(:status)

        helpers = Module.new
        service_class.const_set(:StatusHelpers, helpers)
        service_class.send(:include, helpers)
      end

      def self.configure(service_class, success:, failure:)
        service_class::StatusHelpers.module_eval do
          success.each do |name|
            define_method(name) do |**opts, &block|
              success(status: name, **opts, &block)
            end
          end

          failure.each do |name|
            define_method(name) do |**opts, &block|
              failure(status: name, **opts, &block)
            end
          end
        end
      end

      def status
        state.status
      end

      private def success!(status: :success, **)
        state.status = status
        super
      end

      private def success(status: :success, **)
        state.status = status
        super
      end

      private def failure!(status: :failure, **)
        state.status = status
        super
      end

      private def failure(status: :failure, **)
        super.tap do
          state.status = status
        end
      end

      private def result_with(*)
        super
        state.status ||= state.success ? :success : :failure
      end
    end
  end
end
