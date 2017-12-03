module Excom
  module Plugins::Sentry
    class Sentinel
      def self.deny_with(reason)
        return self.denial_reason = reason unless block_given?

        klass = Class.new(self, &Proc.new)
        klass.denial_reason = reason
        sentinels << klass
      end

      def self.denial_reason=(reason)
        @denial_reason = reason
      end

      def self.denial_reason
        @denial_reason ||= :denied
      end

      def self.allow(*actions)
        actions.each do |name|
          define_method("#{name}?") { true }
        end
      end

      def self.deny(*actions, with: nil)
        return deny_with(with){ deny(*actions) } unless with.nil?

        actions.each do |name|
          define_method("#{name}?") { false }
        end
      end

      def self.sentinels
        @sentinels ||= []
      end

      attr_reader :command

      def initialize(command)
        @command = command
      end

      def denial_reason(action)
        method = "#{action}?"

        reason = sentries.reduce(nil) do |result, sentry|
          result || (sentry.class.denial_reason unless !sentry.respond_to?(method) || sentry.public_send(method))
        end

        Proc === reason ? instance_exec(&reason) : reason
      end

      def sentry(klass)
        unless Class === klass
          klass_name = self.class.name.sub(/[^:]+\Z/, ''.freeze) + "_#{klass}".gsub!(/(_([a-z]))/){ $2.upcase } + 'Sentry'.freeze
          klass = klass_name.respond_to?(:constantize) ?
            klass_name.constantize :
            klass_name.split('::'.freeze).reduce(Object){ |obj, name| obj.const_get(name) }
        end

        klass.new(command)
      end

      def to_hash
        sentries.reduce({}) do |result, sentry|
          partial = sentry.public_methods(false).grep(/\?$/).each_with_object({}) do |method, hash|
            hash[method.to_s[0...-1]] = !!sentry.public_send(method)
          end

          result.merge!(partial){ |_k, old, new| old && new }
        end
      end

      private def sentries
        [self] + sentinels
      end

      private def sentinels
        @sentinels ||= self.class.sentinels.map do |klass|
          klass.new(command)
        end
      end

      def method_missing(name, *)
        if name.to_s.end_with?(??)
          sentinels[1..-1].each do |sentry|
            return sentry.public_send(name) if sentry.respond_to?(name)
          end
        end

        super
      end
    end
  end
end
