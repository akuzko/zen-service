# frozen_string_literal: true

module TestInheritancePlugin
  extend Zen::Service::Plugins::Plugin

  default_options some_option: false

  register_as :test_inheritance

  def self.used(service_class, **)
    service_class.used_count = (service_class.used_count || 0) + 1
  end

  def self.configure(service_class, **opts)
    service_class.configure_count = (service_class.configure_count || 0) + 1
    service_class.last_config_opts = opts
  end
end

module TestPluginWithoutConfigure
  extend Zen::Service::Plugins::Plugin

  register_as :test_no_configure

  def self.used(service_class, **)
    service_class.used_without_configure = true
  end

  def test_method
    :tested
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

      it "handles cloning correctly" do
        cloned = service.clone
        expect(cloned.foo).to eq(1)
        expect(cloned).not_to be(service)

        # Verify attributes are independent
        cloned_with_attrs = cloned.with_attributes(bar: 3)
        expect(service.bar).to be_nil
        expect(cloned_with_attrs.bar).to eq(3)
      end
    end

    describe ".from" do
      let(:source_service) { build_service(foo: 1, bar: 2, baz: 3) }

      it "creates a new service from another service's attributes" do
        new_service = service_class.from(source_service)
        expect(new_service.foo).to eq(1)
        expect(new_service.bar).to eq(2)
        expect(new_service.baz).to eq(3)
        expect(new_service).not_to be(source_service)
      end
    end

    context "when passing duplicate attributes" do
      it "fails when same attribute passed as positional and named" do
        expect { build_service(1, foo: 2) }.to raise_error(ArgumentError, /has already been provided/)
      end
    end
  end

  describe ".call and .[] helpers" do
    def_service do
      attributes :foo, :bar

      def call
        block_given? ? yield(foo, bar) : foo + bar
      end
    end

    specify ".call" do
      result = service_class.(2, 3)
      expect(result).to eq(5)
    end

    specify ".[]" do
      result = service_class[2, 3]
      expect(result).to eq(5)
    end

    context "with a block" do
      specify ".call" do
        result = service_class.(2, 3) { |f, b| f * b }
        expect(result).to eq(6)
      end

      specify ".[]" do
        result = service_class[2, 3] { |f, b| f * b }
        expect(result).to eq(6)
      end
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
        use :test_inheritance, inherited: true, some_option: true
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
      expect(base_class.last_config_opts).to eq(base: true, some_option: false)
      expect(inherited_class.last_config_opts).to eq(inherited: true, some_option: true)
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

  describe ".using?" do
    def_service do
      use :persisted_result
    end

    it "returns true for used plugins" do
      expect(service_class.using?(:persisted_result)).to be true
      expect(service_class.using?(:callable)).to be true
    end

    it "returns false for unused plugins" do
      expect(service_class.using?(:result_yielding)).to be false
    end
  end

  describe "plugin without configure method" do
    let(:base_class) do
      Class.new(Zen::Service) do
        class << self
          attr_accessor :used_without_configure
        end

        use :test_no_configure
      end
    end

    let(:inherited_class) do
      Class.new(base_class) do
        use :test_no_configure
      end
    end

    it "works correctly when re-used in child class" do
      expect(base_class.used_without_configure).to be true
      expect(base_class.new).to respond_to(:test_method)
      expect(inherited_class.new.test_method).to eq(:tested)
    end
  end
end
