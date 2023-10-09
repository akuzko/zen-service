# frozen_string_literal: true

require "spec_helper"

RSpec.describe Zen::Service::Plugins::Plugin do
  module ::SpecPlugin
    extend Zen::Service::Plugins::Plugin

    register_as :custom_name
    default_options foo: 5

    def self.used(service_class, **, &block)
      service_class.class_eval(&block) unless block.nil?
    end

    def foo
      self.class.plugins[:custom_name].options[:foo]
    end

    module ClassMethods
      def bar
        :bar
      end
    end

    module ServiceMethods
      def baz
        :baz
      end
    end

    service_extension ServiceMethods
  end

  describe "DSL methods" do
    def_service do
      use :custom_name do
        def bar
          7
        end
      end
    end

    let(:service) { build_service }

    it "allows to use custom naming, default options and service extension" do
      expect(service.foo).to eq(5)
      expect(service.class.bar).to eq(:bar)
      expect(::Zen::Service.baz).to eq(:baz)
    end

    it "allows to use block" do
      expect(service.bar).to eq(7)
    end
  end

  describe "custom options" do
    def_service do
      use :custom_name, foo: 6
    end

    it "allows to use custom options" do
      expect(build_service.foo).to eq(6)
    end
  end
end
