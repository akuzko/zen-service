require 'spec_helper'

RSpec.describe 'Excom::Plugins::Caching' do
  def_service do
    use :caching
    opts :foo

    def execute!
      calculate_result
    end

    private def calculate_result
      foo * 2
    end
  end

  let(:service) { build_service(foo: 2) }

  it 'runs execution logic only once' do
    expect(service).to receive(:calculate_result).once.and_call_original
    expect(service.execute).to be_success
    expect(service.result).to eq 4
    expect(service).to be_executed
    expect(service.execute.result).to eq 4
  end
end
