module Excom
  module Plugins
    autoload :Pluggable, 'excom/plugins/pluggable'
    autoload :Executable, 'excom/plugins/executable'
    autoload :Context, 'excom/plugins/context'
    autoload :Sentry, 'excom/plugins/sentry'

    module_function

    def fetch(name)
      require("excom/plugins/#{name}") unless plugins.key?(name)

      plugins[name] || fail("extension `#{name}` is not registered")
    end

    def register(name, extension, options = {})
      if plugins.key?(name)
        fail ArgumentError, "extension `#{name}` is already registered"
      end
      extension.singleton_class.send(:define_method, :excom_options) { options }
      plugins[name] = extension
    end

    def plugins
      @plugins ||= {}
    end
  end
end
