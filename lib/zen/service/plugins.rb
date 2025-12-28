# frozen_string_literal: true

module Zen
  module Service::Plugins
    def self.fetch(name)
      raise("extension `#{name}` is not registered") unless plugins.key?(name)

      extension = plugins[name]
      extension.is_a?(String) ? constantize(extension) : extension
    end

    def self.register(name_or_hash, extension = nil)
      if name_or_hash.is_a?(Hash)
        name_or_hash.each do |name, ext|
          register(name, ext)
        end
      else
        raise ArgumentError, "extension must be given" if extension.nil?

        plugins[name_or_hash] =
          if (old_name = plugins.key(extension))
            plugins.delete(old_name)
          else
            extension
          end
      end
    end

    def self.plugins
      @plugins ||= {}
    end

    def self.constantize(string)
      return string.constantize if string.respond_to?(:constantize)

      string.sub(/^::/, "").split("::").inject(Object) { |obj, const| obj.const_get(const) }
    end
  end

  require_relative "plugins/plugin"
  require_relative "plugins/pluggable"
  require_relative "plugins/callable"
  require_relative "plugins/attributes"
  require_relative "plugins/persisted_result"
  require_relative "plugins/result_yielding"
end
