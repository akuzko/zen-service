# frozen_string_literal: true

module Zen
  module Service::SpecHelpers
    def self.included(target)
      target.extend(ClassMethods)
    end

    # Example:
    #   stub_service(MyService)
    #     .with_atributes(foo: 'foo')
    #     .with_stubs(result: 'bar', success: true)
    #     .service
    def stub_service(service)
      ServiceMocker.new(self).stub_service(service)
    end

    module ClassMethods
      def service_context(&block)
        around do |example|
          ::Zen::Service.with_context(instance_exec(&block)) do
            example.run
          end
        end
      end
    end

    class ServiceMocker < SimpleDelegator
      attr_reader :service_class, :service

      def stub_service(service_class) # rubocop:disable Metrics/AbcSize
        @service_class = service_class
        @service = double(service_class.name)

        allow(service_class).to receive(:new).and_return(service)
        allow(service).to receive(:execute).and_return(service)
        allow(service).to receive(:executed?).and_return(true)

        self
      end

      def with_attributes(*attributes)
        expect(service_class).to receive(:new).with(*attributes).and_return(service)

        self
      end

      def with_stubs(stubs)
        stubs[:success?] = !!stubs[:result] unless stubs.key?(:success)
        stubs[:failure?] = !stubs[:success?]

        stubs.each do |name, value|
          allow(service).to receive(name).and_return(value)
        end

        self
      end
    end
  end
end
