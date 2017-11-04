module Excom
  module Plugins::Caching
    Plugins.register :caching, self, use_with: :prepend

    def execute(*)
      return super if block_given? || !executed?

      self
    end
  end
end
