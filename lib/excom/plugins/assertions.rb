module Excom
  module Plugins::Assertions
    Plugins.register :assertions, self

    def assert(fail_with: self.fail_with)
      if yield
        @success = true unless defined?(@success)
        @status = :success unless defined?(@status)
      else
        failure!(fail_with)
      end
    end
  end
end
