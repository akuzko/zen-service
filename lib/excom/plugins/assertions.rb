module Excom
  module Plugins::Assertions
    Plugins.register :assertions, self

    def assert(fail_with: self.fail_with)
      failure!(fail_with) unless yield
    end
  end
end
