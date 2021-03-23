# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Zen::Service::SpecHelpers" do
  class ::SpecHelpersService < Zen::Service
    use :context

    attributes :foo

    def execute!
      context[:foo]
    end
  end

  describe "stub_service" do
    before do
      stub_service(SpecHelpersService)
        .with_attributes(5)
        .with_stubs(result: 6)
    end

    it "provides service stubs" do
      service = SpecHelpersService.new(5)
      expect(service.execute).to be_success
      expect(service.result).to eq(6)
    end
  end

  describe "service_context" do
    service_context { { foo: 5 } }

    it "allows to set service context" do
      service = SpecHelpersService.new
      expect(service.execute.result).to eq(5)
    end
  end
end
