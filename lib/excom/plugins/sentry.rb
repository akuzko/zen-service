module Excom
  module Plugins::Sentry
    autoload :Sentinel, 'excom/plugins/sentry/sentinel'

    Plugins.register :sentry, self

    def self.used(command_class, **opts)
      klass = opts[:class]

      command_class._sentry_class = klass if klass
    end

    def execute
      reason = why_cant(:execute)

      return super if reason.nil?

      failure!(reason)

      self
    end

    def can?(action)
      why_cant(action).nil?
    end

    def why_cant(action)
      sentry.denial_reason(action)
    end

    def sentry
      @sentry ||= self.class.sentry_class.new(self)
    end

    module ClassMethods
      attr_writer :_sentry_class

      def sentry_class
        if _sentry_class.is_a?(String)
          _sentry_class.split('::').reduce(Object){ |obj, name| obj.const_get(name) }
        else
          _sentry_class
        end
      end

      def _sentry_class
        @_sentry_class ||= "#{name}Sentry"
      end
    end
  end
end
