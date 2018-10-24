require 'spec_helper'

RSpec.describe 'Excom::Plugins::StatusHelpers' do
  def_service do
    use :status_helpers,
      success: [:ok],
      failure: [:not_ok]

    opts :all_good

    def execute!
      if all_good
        ok :fine
      else
        not_ok :error
      end
    end
  end

  describe 'success helpers' do
    let(:service) { build_service(all_good: true) }

    it 'executes correctly' do
      expect(service.execute.result).to be :fine
      expect(service.status).to be :ok
      expect(service).to be_success
    end
  end

  describe 'failure helpers' do
    let(:service) { build_service(all_good: false) }

    it 'executes correctly' do
      expect(service.execute.cause).to be :error
      expect(service.status).to be :not_ok
      expect(service).not_to be_success
    end
  end
end
