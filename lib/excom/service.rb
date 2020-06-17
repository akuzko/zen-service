module Excom
  class Service
    extend Excom::Plugins::Pluggable

    use :executable
    use :attributes
  end
end
