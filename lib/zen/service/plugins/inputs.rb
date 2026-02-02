# frozen_string_literal: true

module Zen
  module Service::Plugins
    module Inputs
      extend Plugin

      class Input < Data.define(:name, :optional, :default, :block)
        def default_or_raise!
          return default&.call if optional?

          raise(ArgumentError, "input #{name} is required")
        end

        def optional?
          !default.nil? || optional
        end
      end

      InitInputsBlock = Data.define(:input_names, :block)

      module ClassMethods
        def inherited(service_class)
          service_class.inputs_list.replace(inputs_list.dup)
          service_class.init_inputs_blocks.replace(init_inputs_blocks.dup)
          super
        end

        def input(name, optional: false, default: nil, &block)
          inputs_list.push(Input.new(name, optional, default, block))
          define_method(name) { @inputs.fetch(name) }
        end

        def inputs(*args, **kwargs, &block)
          args.each { input(_1) }
          kwargs.each { |name, default| input(name, default: default) }
          init_inputs_blocks.push(InitInputsBlock.new(args + kwargs.keys, block)) if block
        end

        def inputs_list
          @inputs_list ||= []
        end

        def input_names
          inputs_list.map(&:name)
        end

        def init_inputs_blocks
          @init_inputs_blocks ||= []
        end
      end

      attr_reader :inputs

      def initialize(**kwargs)
        @inputs = assert_valid_inputs!(kwargs)
        self.class.init_inputs_blocks.each do |init_block|
          instance_exec(*inputs.values_at(*init_block.input_names), &init_block.block)
        end
        super()
      end

      def initialize_clone(*)
        super
        @inputs = @inputs.dup
      end

      private

      def assert_valid_inputs!(actual) # rubocop:disable Metrics/AbcSize
        unexpected = actual.keys - self.class.input_names
        raise(ArgumentError, "wrong inputs #{unexpected.join(', ')} given") if unexpected.any?

        self.class.inputs_list.each_with_object({}) do |reflection, result|
          input_name = reflection.name
          result[input_name] = actual.key?(input_name) ? actual[input_name] : reflection.default_or_raise!
          instance_exec(result[input_name], &reflection.block) if reflection.block
        end
      end
    end
  end
end
