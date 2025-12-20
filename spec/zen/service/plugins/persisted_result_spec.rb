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

  describe ":call_unless_called option" do
    context "when set to true" do
      def_service do
        use :persisted_result, call_unless_called: true

        attributes :foo

        def call
          foo * 3
        end
      end

      let(:service) { build_service(foo: 3) }

      it "calls service when #result is accessed before #call" do
        expect(service).not_to be_called
        expect(service.result).to eq(9)
        expect(service).to be_called
      end
    end
  end
end
