# frozen_string_literal: true

module Zen
  module Service::Plugins
    def self.fetch(name)
      plugins[name] || raise("extension `#{name}` is not registered")
    end

    def self.register(name, extension, options = {})
      raise ArgumentError, "extension `#{name}` is already registered" if plugins.key?(name)

      ::Zen::Service.extend(extension::ServiceMethods) if extension.const_defined?("ServiceMethods")

      extension.singleton_class.send(:define_method, :options) { options }
      plugins[name] = extension
    end

    def self.plugins
      @plugins ||= {}
    end
  end

  require_relative "plugins/pluggable"
  require_relative "plugins/executable"
  require_relative "plugins/attributes"
  require_relative "plugins/assertions"
  require_relative "plugins/context"
  require_relative "plugins/execution_cache"
  require_relative "plugins/policies"
  require_relative "plugins/rescue"
  require_relative "plugins/status"
  require_relative "plugins/validation"
end
