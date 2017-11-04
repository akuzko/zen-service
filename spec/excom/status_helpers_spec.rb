require 'spec_helper'

RSpec.describe 'Excom::Plugins::StatusHelpers' do
  Kommand do
    use :status_helpers,
      success: [:ok],
      failure: [:not_ok]

    opts :all_good

    def run
      if all_good
        ok :fine
      else
        not_ok :error
      end
    end
  end

  describe 'success helpers' do
    let(:command) { Kommand(all_good: true) }

    it 'executes correctly' do
      expect(command.execute.result).to eq :fine
      expect(command.status).to eq :ok
      expect(command).to be_success
    end
  end

  describe 'failure helpers' do
    let(:command) { Kommand(all_good: false) }

    it 'executes correctly' do
      expect(command.execute.result).to eq :error
      expect(command.status).to eq :not_ok
      expect(command).not_to be_success
    end
  end
end
