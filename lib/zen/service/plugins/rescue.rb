# frozen_string_literal: true

module Zen
  module Service::Plugins
    module Rescue
      Service::Plugins.register :rescue, self

      def self.used(service_class, *)
        service_class.use(:status) unless service_class.using?(:status)
        service_class.add_execution_prop(:error)
      end

      def execute(**opts)
        rezcue = opts.delete(:rescue)
        super
      rescue StandardError => e
        clear_execution_state!
        failure!(status: :error)
        state.error = e
        raise e unless rezcue

        self
      end

      def error
        state.error
      end

      def error?
        status == :error
      end
    end
  end
end
