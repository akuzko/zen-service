module Excom
  module Plugins::StatusHelpers
    Plugins.register :status_helpers, self

    def self.used(klass, success: [], failure: [])
      klass.success_aliases = success

      helpers = Module.new do
        (success + failure).each do |name|
          define_method(name) do |result|
            @status = name
            @result = result
          end
        end
      end

      klass.const_set('StatusHelpers', helpers)
      klass.send(:include, helpers)
    end

    def success?
      super || self.class.success_aliases.include?(status)
    end

    module ClassMethods
      def success_aliases=(aliases)
        singleton_class.send(:define_method, :success_aliases) { aliases }
      end
    end
  end
end
