module Excom
  module Plugins::Executable
    Plugins.register :executable, self

    UNDEFINED = :__EXCOM_UNDEFINED__
    private_constant :UNDEFINED

    def initialize(*)
      @executed = false
      super
    end

    def initialize_clone(*)
      clear_execution_state!
    end

    def execute(*, &block)
      clear_execution_state!
      result = run(&block)
      result_with(result) unless defined? @result
      @executed = true

      self
    end

    def executed?
      @executed
    end

    private def run
      success!
    end

    private def clear_execution_state!
      @executed = false
      remove_instance_variable('@result') if defined?(@result)
      remove_instance_variable('@status') if defined?(@status)
    end

    def result(obj = UNDEFINED)
      return @result if obj == UNDEFINED

      case obj
      when Hash
        if obj.length != 1
          fail ArgumentError, "expected 1-item status-result pair, got: #{obj.inspect}"
        end

        @status, @result = obj.first
      else
        result_with(obj)
      end
    end

    private def result_with(obj)
      @status = obj ? :success : fail_with unless defined?(@status)
      @result = obj
    end

    def status(status = UNDEFINED)
      return @status = status unless status == UNDEFINED

      @status
    end

    def success?
      status == :success
    end

    def failure?
      !success?
    end

    private def success!
      @status = :success
      @result = true
    end

    private def failure!(status = fail_with)
      @status = status
    end

    protected def fail_with
      self.class.fail_with
    end

    module ClassMethods
      def method_added(name)
        private :run if name == :run
        super if defined? super
      end

      def fail_with(status = nil)
        return @fail_with || :failure if status.nil?

        @fail_with = status
      end

      def call(*args)
        new(*args).execute
      end

      def [](*args)
        call(*args).result
      end
    end
  end
end
