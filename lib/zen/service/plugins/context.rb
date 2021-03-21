# frozen_string_literal: true

module Zen
  module Service::Plugins
    module Context
      extend Plugin

      attr_accessor :local_context
      protected :local_context, :local_context=

      def context
        global_context = ::Zen::Service.context
        return global_context if local_context.nil?

        if global_context.respond_to?(:merge)
          global_context.merge(local_context)
        else
          local_context
        end
      end

      def with_context(ctx)
        clone.tap do |copy|
          copy.local_context =
            copy.local_context.respond_to?(:merge) ? copy.local_context.merge(ctx) : ctx
        end
      end

      def execute(*)
        ::Zen::Service.with_context(context) do
          super
        end
      end

      module ServiceMethods
        def with_context(ctx)
          current = context
          Thread.current[:zen_service_context] = context.respond_to?(:merge) ? context.merge(ctx) : ctx

          yield
        ensure
          Thread.current[:zen_service_context] = current
        end

        def context
          Thread.current[:zen_service_context]
        end
      end

      service_extension ServiceMethods
    end
  end
end
