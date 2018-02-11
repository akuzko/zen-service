require 'spec_helper'
require 'dry-struct'

RSpec.describe 'Excom::Plugins::DryTypes' do
  Kommand do
    use :dry_types
    use :sentry

    constructor_type :strict

    attribute :foo, Dry::Types['int']

    def run
      foo * 2
    end

    sentry do
      def execute?
        foo > 0
      end
    end
  end

  let(:command) { Kommand(foo: 2) }

  describe 'usage' do
    it 'allows to set constructor type' do
      expect{ kommand_class.new(foo: 2, bar: 3) }.to raise_error(Dry::Struct::Error)
    end

    it 'initializes properly' do
      expect(command.foo).to eq 2
    end

    it 'executes properly' do
      expect(command.execute.result).to eq 4
    end

    it 'delegates attributes to sentry' do
      expect(command.sentry_hash).to eq('execute' => true)
    end

    describe '#with_attributes' do
      it 'creates a copy with merged attributes' do
        copy = command.with_attributes(foo: 3)
        expect(copy.foo).to eq 3
      end
    end
  end

  describe 'overriding and deprecation of args and opts' do
    it 'raises errors for .args and .opts methods' do
      expect{ kommand_class.args }.to raise_error(/method is not available/)
      expect{ kommand_class.opts }.to raise_error(/method is not available/)
    end

    it 'raises errors for #with_args and #with_opts methods' do
      expect{ command.with_args }.to raise_error(/method is not available/)
      expect{ command.with_opts }.to raise_error(/method is not available/)
    end
  end
end
