module Excom
  module Plugins::Context
    Plugins.register :context, self

    def context
      ::Excom.context
    end

    def with_context(*args)
      ::Excom.with_context(*args) do
        yield
      end
    end

    module Global
      def with_context(ctx)
        current, Thread.current[:excom_context] = \
          context, context.respond_to?(:merge) ? context.merge(ctx) : ctx
        yield
      ensure
        Thread.current[:excom_context] = current
      end

      def context
        Thread.current[:excom_context] || {}
      end
    end
  end
end
