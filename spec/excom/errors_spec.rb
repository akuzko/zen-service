require 'spec_helper'

RSpec.describe 'Excom::Plugins::Errors' do
  let(:service) { build_service }

  describe ':errors_class option' do
    describe 'default behavior' do
      def_service do
        use :errors
      end

      it 'uses Hash by default' do
        expect(service.execute.errors).to be_an_instance_of(Hash)
      end
    end

    context 'when given' do
      def_service do
        my_errors = Class.new(Hash) do
          def self.name
            'MyErrors'
          end
        end
        use :errors, errors_class: my_errors
      end

      it 'uses specified class for errors object' do
        expect(service.execute.errors.class.name).to eq('MyErrors')
      end
    end
  end

  describe ':fail_if_present option' do
    describe 'default behavior' do
      def_service do
        use :errors

        def execute!
          result { true }
          errors[:foo] = :bar
        end
      end

      it 'fails if errors are present after execution' do
        expect(service.execute).not_to be_success
        expect(service.errors).not_to be_empty
      end
    end

    context 'when set to false' do
      def_service do
        use :errors, fail_if_present: false

        def execute!
          result { true }
          errors[:foo] = :bar
        end
      end

      it "doesn't fail if errors are present after execution" do
        expect(service.execute).to be_success
        expect(service.errors).not_to be_empty
      end
    end
  end
end
