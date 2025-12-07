# frozen_string_literal: true

require "spec_helper"

RSpec.describe Zen::Service::Plugins::PersistedResult do
  def_service do
    use :persisted_result

    attributes :foo

    def call
      foo * 2
    end
  end

  let(:service) { build_service(foo: 2) }

  it "provides #called? method and #result reader" do
    expect(service.call).to eq(4)
    expect(service.result).to eq(4)
    expect(service).to be_called
  end
end
