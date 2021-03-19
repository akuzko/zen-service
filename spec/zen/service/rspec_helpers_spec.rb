# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Zen::Service::SpecHelpers" do
  class ::SpecHelpersService < Zen::Service
    attributes :foo

    def execute!
      failure!
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
end
