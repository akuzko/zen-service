module Excom
  module Plugins::ExecutionCache
    Plugins.register :execution_cache, self

    def initialize(*)
      super
      extend Extension
    end

    module Extension
      def execute(*)
        return super if block_given? || !executed?

        self
      end
    end
  end
end
