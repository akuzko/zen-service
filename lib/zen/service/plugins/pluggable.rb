# frozen_string_literal: true

module Zen
  module Service::Plugins
    module Pluggable
      def use(name, **opts, &block)
        extension = Service::Plugins.fetch(name)

        defaults = extension.config[:default_options]
        opts = defaults.merge(opts) unless defaults.nil?

        if using?(name)
          extension.configure(self, **opts, &block) if extension.respond_to?(:configure)
          return extension
        end

        use_extension(extension, name, **opts, &block)
      end

      private def use_extension(extension, name, **opts, &block)
        include extension
        extend extension::ClassMethods if extension.const_defined?(:ClassMethods)

        extension.used(self, **opts, &block) if extension.respond_to?(:used)
        extension.configure(self, **opts, &block) if extension.respond_to?(:configure)

        plugins[name] = Reflection.new(extension, opts.merge(block: block))

        extension
      end

      def using?(name)
        plugins.key?(name)
      end

      def plugins
        @plugins ||= {}
      end
      alias extensions plugins

      Reflection = Struct.new(:extension, :options)
    end
  end
end
