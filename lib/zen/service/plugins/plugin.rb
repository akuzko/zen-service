# frozen_string_literal: true

module Zen
  module Service::Plugins
    module Plugin
      def self.extended(plugin)
        name = plugin.name.sub(/^.*::/, "").gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase.to_sym

        Service::Plugins.register(name, plugin)
      end

      def register_as(name)
        Service::Plugins.register(name, self)
      end

      def default_options(options)
        config[:default_options] = options
      end

      def service_extension(extension)
        ::Zen::Service.send(:extend, extension)
      end

      def config
        @config ||= {}
      end
    end
  end
end
