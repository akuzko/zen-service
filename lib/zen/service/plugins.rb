# frozen_string_literal: true

module Zen
  module Service::Plugins
    def self.fetch(name)
      require("zen/service/plugins/#{name}") unless plugins.key?(name)

      plugins[name] || raise("extension `#{name}` is not registered")
    end

    def self.register(name, extension)
      raise(ArgumentError, "extension `#{name}` is already registered") if plugins.key?(name)

      plugins[name] =
        if (old_name = plugins.key(extension))
          plugins.delete(old_name)
        else
          extension
        end
    end

    def self.plugins
      @plugins ||= {}
    end
  end

  require_relative "plugins/plugin"
  require_relative "plugins/pluggable"
  require_relative "plugins/callable"
  require_relative "plugins/attributes"
  require_relative "plugins/persisted_result"
  require_relative "plugins/result_yielding"
end
