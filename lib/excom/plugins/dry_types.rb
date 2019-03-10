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

      super
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

    # args and opts overloads
    private def resolve_args!(args)
      [nil, nil]
    end

    private def assert_valid_args!(*)
    end

    private def assert_valid_opts!(*)
    end

    def with_args(*)
      raise("`with_args' method is not available with :dry_types plugin. use `with_attributes' method instead")
    end

    def with_opts(*)
      raise("`with_opts' method is not available with :dry_types plugin. use `with_attributes' method instead")
    end

    module ClassMethods
      def args(*)
        raise("`args' method is not available with :dry_types plugin. use `attribute' method instead")
      end

      def opts(*)
        raise("`args' method is not available with :dry_types plugin. use `attribute' method instead")
      end

      def attribute(name, *args)
        const_get(:Attributes).send(:attribute, name, *args)
        arg_methods.send(:define_method, name){ @attributes.send(name) }
      end
    end
  end
end
