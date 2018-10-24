module Excom
  module Plugins::Errors
    Plugins.register :errors, self,
      default_options: {errors_class: Hash, fail_if_present: true}

    def execute(*)
      super

      if self.class.plugins[:errors].options[:fail_if_present] && !errors.empty?
        failure! { :invalid }
      end

      self
    end

    def errors
      @errors ||= errors_class.new
    end

    private def errors_class
      self.class.plugins[:errors].options[:errors_class]
    end

    private def clear_execution_state!
      if errors.respond_to?(:clear)
        errors.clear
      else
        @errors = errors_class.new
      end

      super
    end
  end
end
