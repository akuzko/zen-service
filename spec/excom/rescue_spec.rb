require 'spec_helper'

RSpec.describe 'Excom::Plugins::Rescue' do
  def_service do
    use :rescue

    def execute!
      fail 'foo'
    end
  end

  let(:service) { build_service }

  context 'when :rescue option is used' do
    it 'rescues from an error' do
      expect{ service.execute(rescue: true) }.not_to raise_error
      expect(service).not_to be_executed
      expect(service).to be_error
      expect(service.status).to eq :error
      expect(service.error.message).to eq 'foo'
    end

    describe 'clearing :error for clone' do
      it 'clears error' do
        service.execute(rescue: true)
        cloned = service.with_attributes({})
        expect(cloned.error).to be nil
      end
    end
  end

  context 'when resuce option is not used' do
    it 'raises an error' do
      expect{ service.execute }.to raise_error('foo')
    end
  end
end
