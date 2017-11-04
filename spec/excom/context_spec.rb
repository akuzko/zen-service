require 'spec_helper'

RSpec.describe 'Excom::Plugins::Context' do
  Kommand do
    use :context

    def run
      context[:foo]
    end
  end

  let(:command) { Kommand() }

  it 'accepts global context' do
    Excom.with_context(foo: 'foo') do
      expect(command.execute.result).to eq 'foo'
    end
  end

  describe '#with_context' do
    it 'merges local context into global context' do
      Excom.with_context(foo: 'foo') do
        expect(command.with_context(foo: 'bar').execute.result).to eq 'bar'
      end
    end
  end
end
