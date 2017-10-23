module Excom
  module Plugins::OneTimeExecute
    Plugins.register :one_time_execute, self

    def execute(*)
      return self if executed?

      super
    ensure
      @executed = true
      self
    end

    def executed?
      !!@executed
    end
  end
end
