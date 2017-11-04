module Excom
  module Plugins::Rescue
    Plugins.register :rescue, self

    attr_reader :error

    def execute(**opts)
      rezcue = opts.delete(:rescue)
      super
    rescue StandardError => error
      clear_execution_state!
      @error = error
      @status = :error
      raise error unless rezcue
      self
    end

    def error?
      status == :error
    end
  end
end