module Excom
  class Service
    extend Excom::Plugins::Pluggable

    use :executable
    use :args
  end
end
