module Excom
  class Service
    autoload :SpecHelpers, 'excom/service/spec_helpers'

    extend Excom::Plugins::Pluggable

    use :executable
    use :attributes
  end
end
