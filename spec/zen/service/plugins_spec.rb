# frozen_string_literal: true

require "spec_helper"

RSpec.describe Zen::Service::Plugins do
  describe ".register" do
    after do
      # Clean up test plugins
      described_class.plugins.delete(:test_plugin)
      described_class.plugins.delete(:renamed_plugin)
    end

    context "with single plugin registration" do
      let(:plugin_module) { Module.new }

      it "registers a plugin with given name" do
        described_class.register(:test_plugin, plugin_module)
        expect(described_class.plugins[:test_plugin]).to eq(plugin_module)
      end

      it "raises an error when extension is nil" do
        expect { described_class.register(:test_plugin, nil) }.to raise_error(ArgumentError, "extension must be given")
      end
    end

    context "with hash registration" do
      let(:plugin1) { Module.new }
      let(:plugin2) { Module.new }

      it "registers multiple plugins" do
        described_class.register(test_plugin: plugin1, another_plugin: plugin2)
        expect(described_class.plugins[:test_plugin]).to eq(plugin1)
        expect(described_class.plugins[:another_plugin]).to eq(plugin2)
      end
    end

    context "when re-registering existing plugin" do
      let(:plugin_module) { Module.new }

      it "updates the plugin name and removes old name" do
        described_class.register(:test_plugin, plugin_module)
        expect(described_class.plugins[:test_plugin]).to eq(plugin_module)

        described_class.register(:renamed_plugin, plugin_module)
        expect(described_class.plugins[:renamed_plugin]).to eq(plugin_module)
        expect(described_class.plugins).not_to have_key(:test_plugin)
      end
    end
  end

  describe ".fetch" do
    let(:plugin_module) { Module.new }

    before do
      described_class.register(:test_plugin, plugin_module)
    end

    after do
      described_class.plugins.delete(:test_plugin)
      described_class.plugins.delete(:string_plugin)
    end

    it "fetches registered plugin by name" do
      expect(described_class.fetch(:test_plugin)).to eq(plugin_module)
    end

    it "raises an error for unregistered plugin" do
      expect { described_class.fetch(:nonexistent) }.to raise_error("extension `nonexistent` is not registered")
    end

    context "when plugin is registered as string" do
      before do
        described_class.register(:string_plugin, "Zen::Service::Plugins::Callable")
      end

      it "constantizes the string" do
        expect(described_class.fetch(:string_plugin)).to eq(Zen::Service::Plugins::Callable)
      end
    end
  end

  describe ".constantize" do
    it "converts string to constant" do
      expect(described_class.constantize("Zen::Service")).to eq(Zen::Service)
    end

    it "handles strings with leading ::" do
      expect(described_class.constantize("::Zen::Service")).to eq(Zen::Service)
    end

    it "handles nested constants" do
      expect(described_class.constantize("Zen::Service::Plugins")).to eq(Zen::Service::Plugins)
    end

    context "when string responds to constantize" do
      let(:string_with_constantize) do
        Class.new(String) do
          def initialize
            super("Zen::Service")
          end

          def constantize
            Zen::Service
          end
        end.new
      end

      it "uses the constantize method" do
        expect(described_class.constantize(string_with_constantize)).to eq(Zen::Service)
      end
    end
  end

  describe ".plugins" do
    it "returns a hash" do
      expect(described_class.plugins).to be_a(Hash)
    end

    it "includes registered plugins" do
      expect(described_class.plugins).to include(:callable, :attributes, :persisted_result, :result_yielding)
    end
  end
end
