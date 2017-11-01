module Excom
  class Command
    extend Excom::Plugins::Pluggable

    use :executable
    use :args

    def self.call(*args)
      new(*args).execute
    end
  end
end
