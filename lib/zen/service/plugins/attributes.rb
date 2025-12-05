# frozen_string_literal: true

module Zen
  module Service::Plugins
    module Attributes
      extend Plugin

      def initialize(*args, **kwargs)
        @attributes = assert_valid_attributes!(resolve_args!(args, kwargs))

        super()
      end

      def initialize_clone(*)
        super
        @attributes = @attributes.dup unless @attributes.nil?
      end

      def with_attributes(attributes)
        clone.tap { |copy| copy.attributes.merge!(attributes) }
      end

      protected

      def attributes
        @attributes
      end

      private

      def resolve_args!(args, kwargs) # rubocop:disable Metrics/AbcSize
        attributes = {}
        total_length = args.length + kwargs.length
        allowed_length = self.class.attributes_list.length

        if total_length > allowed_length
          raise ArgumentError, "wrong number of attributes (given #{total_length}, expected 0..#{allowed_length})"
        end

        args.each_with_index do |value, i|
          attributes[self.class.attributes_list[i]] = value
        end

        kwargs.each do |name, value|
          raise(ArgumentError, "attribute #{name} has already been provided as parameter") if attributes.key?(name)

          attributes[name] = value
        end

        attributes
      end

      def assert_valid_attributes!(actual)
        unexpected = actual.keys - self.class.attributes_list

        raise(ArgumentError, "wrong attributes #{unexpected} given") if unexpected.any?

        actual
      end

      module ClassMethods
        def inherited(service_class)
          service_class.const_set(:AttributeMethods, Module.new)
          service_class.send(:include, service_class::AttributeMethods)
          service_class.attributes_list.replace(attributes_list.dup)
          super
        end

        def attribute_methods
          const_get(:AttributeMethods)
        end

        def attributes(*attrs)
          attributes_list.concat(attrs)

          attrs.each do |name|
            attribute_methods.send(:define_method, name) { @attributes[name] }
            attribute_methods.send(:define_method, "#{name}?") { !!@attributes[name] }
          end
        end

        def attributes_list
          @attributes_list ||= []
        end

        def from(service)
          new(service.send(:attributes))
        end
      end
    end
  end
end
