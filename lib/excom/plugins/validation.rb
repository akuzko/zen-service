module Excom
  module Plugins::Validation
    class Errors < Hash
      def add(key, message)
        (self[key] ||= []).push(message)
      end
    end

    Plugins.register :validation, self,
      default_options: { errors_class: Errors }

    def self.used(service_class, *)
      service_class.add_execution_prop(:errors)
    end

    private def initialize(*)
      super
      state.errors = errors_class.new
    end

    def execute(*)
      return super if valid?

      failure!(status: :invalid)

      self
    end

    def errors
      state.errors
    end

    private def errors_class
      self.class.plugins[:validation].options[:errors_class]
    end

    private def validate!
      errors.clear
      validate
    end

    def validate
    end

    def valid?
      validate!
      errors.empty?
    end

    private def clear_execution_state!
      super
      state.errors = errors_class.new
    end
  end
end
