module Excom
  module Plugins::StatusHelpers
    Plugins.register :status_helpers, self

    def self.used(klass, success: [], failure: [])
      helpers = Module.new do
        success.each do |name|
          define_method(name) do |result = nil|
            success(name) { result }
          end
        end

        failure.each do |name|
          define_method(name) do |cause = nil|
            failure(name) { cause }
          end
        end
      end

      klass.const_set('StatusHelpers', helpers)
      klass.send(:include, helpers)
    end
  end
end
