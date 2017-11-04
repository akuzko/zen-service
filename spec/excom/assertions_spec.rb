require 'spec_helper'

RSpec.describe 'Excom::Plugins::Assetions' do
  Kommand do
    use :assertions
    opts :foo

    fail_with :too_low

    def run
      result foo
      assert { foo > 2 }
    end
  end

  context 'when assertion passes' do
    let(:command) { Kommand(foo: 3) }

    specify 'command is executed successfully' do
      expect(command.execute.result).to eq 3
      expect(command).to be_success
    end
  end

  context 'when assertion fails' do
    let(:command) { Kommand(foo: 2) }

    specify 'command fails' do
      expect(command.execute.result).to eq 2
      expect(command).not_to be_success
      expect(command.status).to eq :too_low
    end
  end
end
