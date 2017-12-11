module Excom
  module Plugins::Context
    Plugins.register :context, self

    attr_accessor :local_context
    protected :local_context, :local_context=

    def context
      global_context = ::Excom.context
      return global_context if local_context.nil?

      global_context.respond_to?(:merge) ?
        (global_context.merge(local_context) rescue local_context) :
        local_context
    end

    def with_context(ctx)
      clone.tap do |copy|
        copy.local_context =
          copy.local_context.respond_to?(:merge) ? copy.local_context.merge(ctx) : ctx
      end
    end

    def local_context
      @local_context
    end

    module ExcomMethods
      def with_context(ctx)
        current, Thread.current[:excom_context] = \
          context, context.respond_to?(:merge) ? context.merge(ctx) : ctx
        yield
      ensure
        Thread.current[:excom_context] = current
      end

      def context
        Thread.current[:excom_context]
      end
    end
  end
end
