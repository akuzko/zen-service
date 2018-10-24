module Excom
  module Plugins::Caching
    Plugins.register :caching, self

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
