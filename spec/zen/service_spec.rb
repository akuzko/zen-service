# frozen_string_literal: true

module TestInheritancePlugin
  extend Zen::Service::Plugins::Plugin

  register_as :test_inheritance

  def self.used(service_class, **)
    service_class.used_count = (service_class.used_count || 0) + 1
  end

  def self.configure(service_class, **opts)
    service_class.configure_count = (service_class.configure_count || 0) + 1
    service_class.last_config_opts = opts
  end
end

RSpec.describe Zen::Service do
  it "has a version number" do
    expect(Zen::Service::VERSION).not_to be nil
  end

  describe "attributes" do
    def_service do
      attributes :foo, :bar
      attributes :baz
    end

    describe "inheritance" do
      let(:inherited_service_class) do
        Class.new(service_class) do
          attributes :bak
        end
      end

      it "inherits attributes list" do
        expect(service_class.attributes_list).to eq(%i[foo bar baz])
        expect(inherited_service_class.attributes_list).to eq(%i[foo bar baz bak])
      end

      specify "reader helpers" do
        base_service = service_class.new
        inherited_service = inherited_service_class.new

        expect(base_service).not_to respond_to(:bak)
        expect(inherited_service).to respond_to(:bak)
      end
    end

    context "when correctly initialized" do
      it "allows to pass attributes as options" do
        service = build_service(foo: 1, baz: 2)

        expect(service.foo).to eq(1)
        expect(service.bar).to be(nil)
        expect(service.baz).to eq(2)
      end

      it "allows to pass attributes as parameters" do
        service = build_service(1, baz: 2)

        expect(service.foo).to eq(1)
        expect(service.bar).to be(nil)
        expect(service.baz).to eq(2)
      end
    end

    context "when too many attributes" do
      it "fails with an error" do
        expect { build_service(1, 2, 3, 4) }.to raise_error(ArgumentError)
      end
    end

    context "when invalid attributes" do
      it "fails with an error" do
        expect { build_service(1, 2, paw: "wow") }.to raise_error(ArgumentError)
      end
    end

    describe "#with_attributes" do
      let(:service) { build_service(foo: 1) }

      it "generates a new service with merged attributes" do
        attrs_service = service.with_attributes(bar: 2)
        expect(attrs_service.foo).to eq(1)
        expect(attrs_service.bar).to eq(2)
      end
    end
  end

  describe ".call and .[] helpers" do
    def_service do
      attributes :arg

      def call
        arg
      end
    end

    specify ".call" do
      result = service_class.(:foo)
      expect(result).to eq(:foo)
    end

    specify ".[]" do
      result = service_class[:foo]
      expect(result).to eq(:foo)
    end
  end

  describe "plugin usage and inheritance" do
    let(:base_class) do
      Class.new(Zen::Service) do
        class << self
          attr_accessor :used_count, :configure_count, :last_config_opts
        end

        use :test_inheritance, base: true
      end
    end

    let(:inherited_class) do
      Class.new(base_class) do
        use :test_inheritance, inherited: true
      end
    end

    it "calls used only once on the base class" do
      expect(base_class.used_count).to eq(1)
      expect(inherited_class.used_count).to be_nil
    end

    it "calls configure on both base and inherited classes" do
      expect(base_class.configure_count).to eq(1)
      expect(inherited_class.configure_count).to eq(1)
    end

    it "passes different options to configure in inherited class" do
      expect(base_class.last_config_opts).to eq(base: true)
      expect(inherited_class.last_config_opts).to eq(inherited: true)
    end
  end

  describe "plugin reflection" do
    def_service do
      use :persisted_result, call_unless_called: true do
        def custom
          :custom
        end
      end
    end

    it "stores block separately from options in reflection" do
      reflection = service_class.plugins[:persisted_result]

      expect(reflection.options).to eq(call_unless_called: true)
      expect(reflection.options).not_to have_key(:block)
      expect(reflection.block).to be_a(Proc)
    end
  end
end
