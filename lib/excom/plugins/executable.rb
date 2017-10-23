module Excom
  module Plugins::Executable
    Plugins.register :executable, self

    def execute(*, &block)
      rezult = run(&block)
      result(rezult) unless defined? @result

      self
    end

    private def run
      success!
    end

    def result(obj = nil)
      return @result if obj.nil?

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

    def status(status = nil)
      return @status = status unless status.nil?

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

    private def assert
      fail! unless yield
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
