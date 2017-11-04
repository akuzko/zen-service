require 'spec_helper'

RSpec.describe 'Excom::Plugins::Rescue' do
  Kommand do
    use :rescue

    def run
      fail 'foo'
    end
  end

  let(:command) { Kommand() }

  context 'when :rescue option is used' do
    it 'rescues from an error' do
      expect{ command.execute(rescue: true) }.not_to raise_error
      expect(command).not_to be_executed
      expect(command).to be_error
      expect(command.status).to eq :error
      expect(command.error.message).to eq 'foo'
    end
  end

  context 'when resuce option is not used' do
    it 'raises an error' do
      expect{ command.execute }.to raise_error('foo')
    end
  end
end
