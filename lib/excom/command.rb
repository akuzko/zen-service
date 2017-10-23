module Excom
  class Command
    extend Excom::Plugins::Pluggable

    use :executable
    use :args
    use :one_time_execute, prepend: true

    def self.call(*args)
      new(*args).execute
    end
  end
end
