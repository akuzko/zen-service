# frozen_string_literal: true

require "spec_helper"

RSpec.describe Zen::Service::Plugins::Status do
  describe "#success" do
    subject(:service) { build_service.execute }

    def_service do
      use :status

      def execute!
        success { :result }
      end
    end

    it { is_expected.to be_success }
    its(:status) { is_expected.to be(:success) }
    its(:result) { is_expected.to be(:result) }

    context "when status is passed" do
      def_service do
        use :status

        def execute!
          success(status: :ok) { :result }
        end
      end

      it { is_expected.to be_success }
      its(:status) { is_expected.to be(:ok) }
      its(:result) { is_expected.to be(:result) }
    end
  end

  describe "#failure" do
    subject(:service) { build_service.execute }

    def_service do
      use :status

      def execute!
        failure { :errors }
      end
    end

    it { is_expected.to be_failure }
    its(:status) { is_expected.to be(:failure) }
    its(:result) { is_expected.to be(:errors) }

    context "when status is passed" do
      def_service do
        use :status

        def execute!
          failure(status: :unprocessable_entity) { :errors }
        end
      end

      it { is_expected.to be_failure }
      its(:status) { is_expected.to be(:unprocessable_entity) }
      its(:result) { is_expected.to be(:errors) }
    end
  end

  describe "#result" do
    subject(:service) { build_service.execute }

    context "when block yields to truthy value" do
      def_service do
        use :status

        def execute!
          result { :result }
        end
      end

      it { is_expected.to be_success }
      its(:status) { is_expected.to eq(:success) }
      its(:result) { is_expected.to eq(:result) }
    end

    context "when block yields to falsy value" do
      def_service do
        use :status

        def execute!
          result { false }
        end
      end

      it { is_expected.to be_failure }
      its(:status) { is_expected.to be(:failure) }
      its(:result) { is_expected.to be(false) }
    end

    context "implicit success" do
      def_service do
        use :status

        def execute!
          :result
        end
      end

      it { is_expected.to be_success }
      its(:status) { is_expected.to eq(:success) }
      its(:result) { is_expected.to eq(:result) }
    end

    context "implicit failure" do
      def_service do
        use :status

        def execute!
          nil
        end
      end

      it { is_expected.to be_failure }
      its(:status) { is_expected.to eq(:failure) }
      its(:result) { is_expected.to be(nil) }
    end
  end

  describe "status helpers" do
    def_service do
      use :status,
          success: [:ok],
          failure: [:not_ok]

      attributes :all_good

      def execute!
        if all_good?
          ok { :fine }
        else
          not_ok { :error }
        end
      end
    end

    describe "success helpers" do
      let(:service) { build_service(all_good: true) }

      it "executes correctly" do
        expect(service.execute.result).to be(:fine)
        expect(service.status).to be(:ok)
        expect(service).to be_success
      end
    end

    describe "failure helpers" do
      let(:service) { build_service(all_good: false) }

      it "executes correctly" do
        expect(service.execute.result).to be(:error)
        expect(service.status).to be(:not_ok)
        expect(service).not_to be_success
      end
    end
  end

  describe "status propagation in service execution delegation" do
    def_service do
      use :status
      attributes :arg

      def execute!
        success(status: :ok) { arg * 2 }
      end
    end

    let(:other_service_class) do
      klass = service_class

      Class.new(Zen::Service) do
        use :status
        attributes :arg

        define_method(:execute!) do
          ~klass.(arg)
        end
      end
    end

    specify "both :status and :result can be delegated via ~@ method" do
      other_service = other_service_class.(5)

      expect(other_service).to be_success
      expect(other_service.status).to be(:ok)
      expect(other_service.result).to be(10)
    end
  end
end
