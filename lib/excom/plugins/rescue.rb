module Excom
  module Plugins::Rescue
    Plugins.register :rescue, self

    attr_reader :error

    def execute(**opts)
      rezcue = opts.delete(:rescue)
      super
    rescue StandardError => error
      @error = error
      @result = nil
      @status = :error
      raise error unless rezcue
      self
    end

    def error?
      status == :error
    end
  end
end
