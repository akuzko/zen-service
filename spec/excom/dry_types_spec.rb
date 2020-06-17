require 'spec_helper'
require 'dry-struct'

RSpec.describe 'Excom::Plugins::DryTypes' do
  def_service do
    use :dry_types

    attribute :foo, Dry::Types['integer']

    def execute!
      foo * 2
    end
  end

  let(:service) { build_service(foo: 2) }

  describe 'usage' do
    it 'initializes properly' do
      expect(service.foo).to eq 2
    end

    it 'executes properly' do
      expect(service.execute.result).to eq 4
    end

    describe '#with_attributes' do
      it 'creates a copy with merged attributes' do
        copy = service.with_attributes(foo: 3)
        expect(copy.foo).to eq 3
      end
    end
  end

  describe 'overriding and deprecation of :attributes' do
    it 'raises errors for .attributes method' do
      expect{ service_class.attributes }.to raise_error(/method is not available/)
    end
  end
end
