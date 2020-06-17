module Excom
  module Plugins::DryTypes
    Plugins.register :dry_types, self

    attr_accessor :attributes
    protected :attributes=

    def self.used(service_class, *)
      require 'dry-types'
      require 'dry-struct'

      service_class.const_set(:Attributes, Class.new(Dry::Struct))
    end

    def initialize(attrs)
      @attributes = self.class::Attributes.new(attrs)

      super(@attributes)
    end

    def initialize_clone(*)
      @attributes = @attributes.dup
      super
    end

    def with_attributes(attrs)
      clone.tap do |copy|
        copy.attributes = self.class::Attributes.new(attributes.to_hash.merge(attrs))
      end
    end

    # :attributes plugin overloads
    private def resolve_args!(args)
      args[0]
    end

    private def assert_valid_attributes!(attrs)
      attrs
    end

    module ClassMethods
      def attributes(*)
        raise("`attribute' method is not available with :dry_types plugin. use `attribute' method instead")
      end

      def attribute(name, *args)
        const_get(:Attributes).send(:attribute, name, *args)
        attribute_methods.send(:define_method, name){ @attributes.send(name) }
      end
    end
  end
end
