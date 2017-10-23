module Excom
  module Plugins::Pluggable
    def use(name, prepend: false, **opts)
      extension = Plugins.fetch(name)

      send(prepend ? :prepend : :include, extension)

      if extension.const_defined?('ClassMethods')
        extend extension::ClassMethods
      end

      if extension.respond_to?(:used)
        extension.used(self, **opts)
      end

      extension
    end
  end
end
