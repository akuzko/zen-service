module Excom
  module Plugins::Pluggable
    def use(name, **opts)
      extension = Plugins.fetch(name)

      method = extension.excom_options[:use_with] || :include
      send(method, extension)

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
