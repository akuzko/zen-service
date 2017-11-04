module Excom
  module Plugins::Context
    Plugins.register :context, self

    def initialize(*)
      @local_context = {}
      super
    end

    def initialize_clone(*)
      @local_context = @local_context.dup
      super
    end

    def context
      global_context = ::Excom.context
      global_context.respond_to?(:merge) ?
        global_context.merge(local_context) :
        local_context
    end

    def with_context(ctx)
      clone.tap{ |copy| copy.local_context.merge!(ctx) }
    end

    protected def local_context
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
        Thread.current[:excom_context] || {}
      end
    end
  end
end
