module Excom
  module Plugins::Args
    Plugins.register :args, self

    def initialize(*args)
      opts = args.last.is_a?(Hash) ? args.pop : {}

      assert_valid_args!(args)
      assert_valid_opts!(opts)

      @args = args
      @opts = opts
    end

    def initialize_clone(*)
      super
      @args = @args.dup
      @opts = @opts.dup
    end

    def with_args(*args)
      clone.tap{ |copy| copy.args.replace(args) }
    end

    def with_opts(opts)
      clone.tap{ |copy| copy.opts.merge!(opts) }
    end

    protected def opts
      @opts
    end

    protected def args
      @args
    end

    private def assert_valid_args!(actual)
      allowed = self.class.args_list.length

      if actual.length > allowed
        fail ArgumentError, "wrong number of args (given #{actual.length}, expected 0..#{allowed})"
      end
    end

    private def assert_valid_opts!(actual)
      unexpected = actual.keys - self.class.opts_list

      if unexpected.any?
        fail ArgumentError, "wrong opts #{unexpected} given"
      end
    end

    module ClassMethods
      def args(*argz)
        args_list.concat(argz)

        argz.each_with_index do |name, i|
          define_method(name){ @args[i] }
        end
      end

      def opts(*optz)
        opts_list.concat(optz)

        optz.each do |name|
          define_method(name){ @opts[name] }
        end
      end

      def args_list
        @args_list ||= []
      end

      def opts_list
        @opts_list ||= []
      end
    end
  end
end