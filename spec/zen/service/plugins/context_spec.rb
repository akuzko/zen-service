# frozen_string_literal: true

require "spec_helper"

RSpec.describe Zen::Service::Plugins::Context do
  def_service do
    use :context

    def execute!
      context[:foo]
    end
  end

  let(:service) { build_service }
  let(:custom_hash) { Class.new(Hash) }

  it "doesn't have any context by default" do
    expect(service.context).to be_nil
  end

  it "accepts global context" do
    Zen::Service.with_context(custom_hash[:foo, "foo"]) do
      expect(service.execute.result).to eq("foo")
      expect(service.context).to be_an_instance_of(custom_hash)
    end
  end

  describe "#with_context" do
    it "merges local context into global context" do
      Zen::Service.with_context(foo: "foo") do
        expect(service.with_context(foo: "bar").execute.result).to eq("bar")
      end
    end

    it "sets local context if not defined and merges otherwise" do
      expect(service.with_context(foo: "bar").with_context(bar: "baz").context)
        .to eq(foo: "bar", bar: "baz")
    end

    describe "using local context during execution" do
      let(:other_service_class) do
        klass = service_class

        Class.new(Zen::Service) do
          use :context

          define_method(:execute!) do
            klass.new.execute.result * 2
          end
        end
      end

      it "uses local context during execution" do
        service = other_service_class.new.with_context(foo: 5)
        expect(service.execute.result).to eq(10)
      end
    end
  end
end
