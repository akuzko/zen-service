# frozen_string_literal: true

module Zen
  module Service::Plugins
    module Policies
      Service::Plugins.register :policies, self

      GuardViolationError = Class.new(StandardError)

      def self.used(service_class, *)
        service_class.partials = []
      end

      private def execute!
        partials.each_with_object({}) do |partial, permissions|
          partial.public_methods(false).grep(/\?$/).each do |action_check|
            key = action_check.to_s[0...-1]
            can = partial.public_send(action_check)

            permissions[key] = permissions.key?(key) ? permissions[key] && can : can
          end
        end
      end

      def can?(action)
        why_cant?(action).nil?
      end

      def guard!(action)
        reason = why_cant?(action)

        return if reason.nil?

        raise(reason) if (reason.is_a?(Class) ? reason : reason.class) < Exception

        raise(GuardViolationError, reason)
      end

      def why_cant?(action)
        action_check = "#{action}?"

        reason =
          partials
          .find { |p| p.respond_to?(action_check) && !p.public_send(action_check) }
            &.class
            &.denial_reason

        reason.is_a?(Proc) ? instance_exec(&reason) : reason
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
end
