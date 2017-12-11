require 'spec_helper'

RSpec.describe 'Excom::Plugins::Context' do
  Kommand do
    use :context

    def run
      context[:foo]
    end
  end

  let(:command) { Kommand() }
  let(:custom_hash) { Class.new(Hash) }

  it "doesn't have any context by default" do
    expect(command.context).to be_nil
  end

  it 'accepts global context' do
    Excom.with_context(custom_hash[:foo, 'foo']) do
      expect(command.execute.result).to eq 'foo'
      expect(command.context).to be_an_instance_of(custom_hash)
    end
  end

  describe '#with_context' do
    it 'merges local context into global context' do
      Excom.with_context(foo: 'foo') do
        expect(command.with_context(foo: 'bar').execute.result).to eq 'bar'
      end
    end

    it 'sets local context if not defined and merges otherwise' do
      expect(command.with_context(foo: 'bar').with_context(bar: 'baz').context)
        .to eq(foo: 'bar', bar: 'baz')
    end
  end
end
