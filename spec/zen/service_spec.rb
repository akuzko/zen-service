# frozen_string_literal: true

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
end
