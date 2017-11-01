module Excom
  module Plugins::Executable
    Plugins.register :executable, self

    UNDEFINED = :__EXCOM_UNDEFINED__
    private_constant :UNDEFINED

    def initialize(*)
      @executed = false
      super
    end

    def execute(*, &block)
      rezult = run(&block)
      result(rezult) unless defined? @result
      @executed = true

      self
    end

    def executed?
      @executed
    end

    private def run
      success!
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
        @status = obj ? :success : fail_with
        @result = obj
      end
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
      @result = false
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
    end
  end
end
