require 'spec_helper'

RSpec.describe 'Excom::Plugins::Caching' do
  Kommand do
    use :caching
    opts :foo

    def run
      calculate_result
    end

    private def calculate_result
      foo * 2
    end
  end

  let(:command) { Kommand(foo: 2) }

  it 'runs execution logic only once' do
    expect(command).to receive(:calculate_result).once.and_call_original
    expect(command.execute).to be_success
    expect(command.result).to eq 4
    expect(command).to be_executed
    expect(command.execute.result).to eq 4
  end
end
