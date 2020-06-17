module Excom
  module Plugins::Abilities
    Plugins.register :abilities, self

    GuardViolationError = Class.new(StandardError)

    def self.used(service_class, *)
      service_class.partials = []
    end

    private def execute!
      partials.each_with_object({}) do |partial, abilities|
        partial.public_methods(false).grep(/\?$/).each do |action_check|
          key = action_check.to_s[0...-1]
          can = partial.public_send(action_check)

          abilities[key] = abilities.key?(key) ? abilities[key] && can : can
        end
      end
    end

    def can?(action)
      why_cant?(action).nil?
    end

    def guard!(action)
      reason = why_cant?(action)

      return if reason.nil?

      if (reason.is_a?(Class) ? reason : reason.class) < Exception
        raise(reason)
      else
        raise(GuardViolationError, reason)
      end
    end

    def why_cant?(action)
      action_check = "#{action}?"

      reason =
        partials
          .find{ |p| p.respond_to?(action_check) && !p.public_send(action_check) }
          &.class
          &.denial_reason

      Proc === reason ? instance_exec(&reason) : reason
    end

    private def partials
      @partials ||= self.class.partials.map do |klass|
        klass.from(self)
      end
    end

    module ClassMethods
      attr_accessor :partials, :denial_reason

      def deny_with(reason, &block)
        partial = Class.new(self, &block)
        partial.denial_reason = reason
        partials << partial
      end
    end
  end
end