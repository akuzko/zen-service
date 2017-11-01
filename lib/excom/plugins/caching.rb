module Excom
  module Plugins::Caching
    Plugins.register :caching, self, use_with: :prepend

    def execute(overrides = {})
      return super if block_given?

      if executed_with?(overrides)
        result execution_cache[overrides]
      else
        super
        execution_cache[overrides] = {status => result}
      end

      self
    end

    def executed_with?(overrides)
      execution_cache.key?(overrides)
    end

    private def execution_cache
      @execution_cache ||= {}
    end
  end
end
