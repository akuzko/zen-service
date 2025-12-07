# frozen_string_literal: true

require "spec_helper"

RSpec.describe Zen::Service::Plugins::Executable do
  def_service do
    use :executable

    attributes :foo

    def call
      foo * 2
    end
  end

  let(:service) { build_service(foo: 2) }

  it "provides #execute, #exucute? methods and #result reader" do
    expect(service.execute).to be(service)
    expect(service.result).to eq(4)
    expect(service).to be_executed
  end
end
