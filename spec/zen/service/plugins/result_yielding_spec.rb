# frozen_string_literal: true

require "spec_helper"

RSpec.describe Zen::Service::Plugins::ResultYielding do
  def_service do
    use :result_yielding

    attributes :foo

    def call
      return yield if foo.odd?

      nested.call do
        foo * 2
      end
    end

    def nested
      @nested ||= with_attributes(foo: foo + 1)
    end
  end

  let(:service) { build_service(foo: 2) }

  it "results with value yielded from block" do
    expect(service.call).to eq(4)
  end
end
