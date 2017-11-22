module Excom
  class Command
    extend Excom::Plugins::Pluggable

    use :executable
    use :args
  end
end
