module Excom
  module Plugins::Status
    Plugins.register :status, self,
      default_options: {success: [], failure: []}

    def self.used(service_class, success:, failure:)
      service_class.add_execution_prop(:status)

      helpers = Module.new do
        success.each do |name|
          define_method(name) do |result = nil|
            success(name) { result }
          end
        end

        failure.each do |name|
          define_method(name) do |result = nil|
            failure(name) { result }
          end
        end
      end

      service_class.const_set('StatusHelpers', helpers)
      service_class.send(:include, helpers)
    end

    def status
      state.status
    end

    private def success!(status = :success)
      state.status = status 
      super()
    end

    private def success(status = :success, &block)
      state.status = status
      super(&block)
    end

    private def failure!(status = :failure)
      state.status = status
      super()
    end

    private def failure(status = :failure, &block)
      super(&block).tap do
        state.status = status
      end
    end

    private def result_with(*)
      super
      state.status ||= state.success ? :success : :failure
    end
  end
end
