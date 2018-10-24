module Excom
  module Plugins::Executable
    Plugins.register :executable, self

    Result = Struct.new(:success, :status, :result, :cause)

    attr_reader :status, :cause

    def initialize(*)
      @executed = false
      super
    end

    def initialize_clone(*)
      clear_execution_state!
    end

    def execute(*, &block)
      clear_execution_state!
      result = execute!(&block)
      result_with(result) unless defined? @result
      @executed = true

      self
    end

    def executed?
      @executed
    end

    def ~@
      Result.new(success?, status, result, cause)
    end

    private def execute!
      success!
    end

    private def clear_execution_state!
      @executed = false
      remove_instance_variable('@result'.freeze) if defined?(@result)
      remove_instance_variable('@status'.freeze) if defined?(@status)
      remove_instance_variable('@cause'.freeze) if defined?(@cause)
      remove_instance_variable('@success'.freeze) if defined?(@success)
    end

    private def finish_with!(status, success:)
      @success = success
      @status = status
      @cause = nil
      @result = nil
    end

    private def success!(status = :success)
      finish_with!(status, success: true)
    end

    private def success(status = :success)
      success!(status)
      @result = yield
    end

    private def failure!(status = fail_with)
      finish_with!(status, success: false)
    end

    private def failure(status = fail_with)
      failure!(status)
      @cause = yield
    end

    def result
      return @result unless block_given?

      result_with(yield)
    end

    private def result_with(obj)
      if Result === obj
        @success, @status, @result, @cause = obj.success, obj.status, obj.result, obj.cause
        return @result
      end

      @success = !!obj
      @status = @success ? :success : fail_with unless defined?(@status)
      @result = obj
    end

    def success?
      @success == true
    end

    def failure?
      !success?
    end

    protected def fail_with
      self.class.fail_with
    end

    module ClassMethods
      def call(*args)
        new(*args).execute
      end

      def [](*args)
        call(*args).result
      end

      def fail_with(status = nil)
        return @fail_with || :failure if status.nil?

        @fail_with = status
      end

      def method_added(name)
        private :execute! if name == :execute!
        super if defined? super
      end
    end
  end
end
