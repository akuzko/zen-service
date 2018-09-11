module Excom
  module Plugins::Sentry
    class Sentinel
      def self.inherited(sentry_class)
        return unless self == Sentinel

        sentry_class.denial_reason = denial_reason
        sentry_class.const_set(:Delegations, Module.new)
        sentry_class.send(:include, sentry_class::Delegations)
      end

      def self.service_class=(klass)
        sentinels.each{ |s| s.service_class = klass }
        @service_class = klass
      end

      def self.service_class
        @service_class
      end

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

      def self.delegations
        const_get(:Delegations)
      end

      attr_reader :service

      def initialize(service)
        @service = service
      end

      def denial_reason(action)
        method = "#{action}?"

        reason = sentries.reduce(nil) do |result, sentry|
          result || (sentry.class.denial_reason unless !sentry.respond_to?(method) || sentry.public_send(method))
        end

        Proc === reason ? instance_exec(&reason) : reason
      end

      def sentry(klass)
        klass = derive_sentry_class(klass) unless Class === klass
        klass.new(service)
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
          klass.new(service)
        end
      end

      private def derive_sentry_class(klass)
        constantize(klass, '::Sentry'.freeze)
      rescue NameError
        constantize(klass, 'Sentry'.freeze)
      end

      private def constantize(klass, sentry_name)
        module_prefix = (inline? ? self.class.service_class.name : self.class.name).sub(/[^:]+\Z/, ''.freeze)

        klass_name = module_prefix + "_#{klass}".gsub!(/(_([a-z]))/){ $2.upcase } + sentry_name

        klass_name.respond_to?(:constantize) ?
          klass_name.constantize :
          klass_name.split('::'.freeze).reduce(Object){ |obj, name| obj.const_get(name) }
      end

      private def inline?
        self.class.service_class.const_defined?(:Sentry) && self.class.service_class::Sentry == self.class
      end

      private def define_delegations!
        delegated_methods = self.class.service_class.arg_methods.instance_methods +
          Array(self.class.service_class.plugins[:sentry].options[:delegate])

        delegated_methods.each do |name|
          self.class.delegations.send(:define_method, name) { service.public_send(name) }
        end

        self.class.instance_variable_set('@delegations_defined'.freeze, true)
      end

      private def delegations_defined?
        self.class.instance_variable_get('@delegations_defined'.freeze)
      end

      def method_missing(name, *args)
        unless delegations_defined?
          define_delegations!
          return send(name, *args) if respond_to?(name)
        end

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
