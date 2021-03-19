# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Zen::Service::Plugins::Validation" do
  let(:service) { build_service }

  describe "behavior" do
    def_service do
      use :validation

      def execute!
        true
      end

      def validate
        errors[:foo] = :bar
      end
    end

    it "fails if errors are present and does not executes main logic" do
      expect(service).not_to receive(:execute!)
      expect(service.execute).not_to be_success
      expect(service.errors).not_to be_empty
    end
  end

  describe ":errors_class option" do
    describe "default behavior" do
      def_service do
        use :validation
      end

      it "uses Validation::Errors by default" do
        expect(service.execute.errors).to be_an_instance_of(Zen::Service::Plugins::Validation::Errors)
      end
    end

    context "when given" do
      def_service do
        my_errors = Class.new(Hash) do
          def self.name
            "MyErrors"
          end
        end
        use :validation, errors_class: my_errors
      end

      it "uses specified class for errors object" do
        expect(service.execute.errors.class.name).to eq("MyErrors")
      end
    end
  end
end
