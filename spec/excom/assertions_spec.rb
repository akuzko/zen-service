require 'spec_helper'

RSpec.describe 'Excom::Plugins::Assetions' do
  def_service do
    use :assertions

    attributes :foo

    def execute!
      result { foo }
      assert { foo > 2 }
    end
  end

  context 'when assertion passes' do
    let(:service) { build_service(foo: 3) }

    specify 'service is executed successfully' do
      expect(service.execute.result).to eq 3
      expect(service).to be_success
    end
  end

  context 'when assertion fails' do
    let(:service) { build_service(foo: 2) }

    specify 'service fails' do
      expect(service.execute.result).to be nil
      expect(service).not_to be_success
    end
  end
end
