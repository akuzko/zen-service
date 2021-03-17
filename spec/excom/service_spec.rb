require 'spec_helper'

RSpec.describe Excom::Service do
  describe 'attributes' do
    def_service do
      attributes :foo, :bar
      attributes :baz
    end

    describe 'inheritance' do
      let(:inherited_service_class) do
        Class.new(service_class) do
          attributes :bak
        end
      end

      it 'inherits attributes list' do
        expect(service_class.attributes_list).to eq([:foo, :bar, :baz])
        expect(inherited_service_class.attributes_list).to eq([:foo, :bar, :baz, :bak])
      end

      specify 'reader helpers' do
        base_service = service_class.new
        inherited_service = inherited_service_class.new

        expect(base_service).not_to respond_to(:bak)
        expect(inherited_service).to respond_to(:bak)
      end
    end

    context 'when correctly initialized' do
      it 'allows to pass attributes as options' do
        service = build_service(foo: 1, baz: 2)

        expect(service.foo).to eq(1)
        expect(service.bar).to be(nil)
        expect(service.baz).to eq(2)
      end

      it 'allows to pass attributes as parameters' do
        service = build_service(1, baz: 2)

        expect(service.foo).to eq(1)
        expect(service.bar).to be(nil)
        expect(service.baz).to eq(2)
      end
    end

    context 'when too many attributes' do
      it 'fails with an error' do
        expect { build_service(1, 2, 3, 4) }.to raise_error(ArgumentError)
      end
    end

    context 'when invalid attributes' do
      it 'fails with an error' do
        expect { build_service(1, 2, paw: 'wow') }.to raise_error(ArgumentError)
      end
    end

    describe '#with_attributes' do
      let(:service) { build_service(foo: 1) }

      it 'generates a new service with merged attributes' do
        attrs_service = service.with_attributes(bar: 2)
        expect(attrs_service.foo).to eq(1)
        expect(attrs_service.bar).to eq(2)
      end

      it 'clears execution flags' do
        service.execute
        expect(service.with_attributes(bar: 2)).not_to be_executed
      end
    end
  end

  describe 'execution' do
    describe '#success' do
      subject(:service) { build_service.execute }

      def_service do
        def execute!
          success { :result }
        end
      end

      it { is_expected.to be_success }
      its(:result) { is_expected.to be(:result) }
    end

    describe '#failure' do
      subject(:service) { build_service.execute }

      def_service do
        def execute!
          failure { :errors }
        end
      end

      it { is_expected.to be_failure }
      its(:result) { is_expected.to be(:errors) }
    end

    describe '#result' do
      subject(:service) { build_service.execute }

      context 'when block yields to truthy value' do
        def_service do
          def execute!
            result { :result }
          end
        end

        it { is_expected.to be_success }
        its(:result) { is_expected.to eq(:result) }
      end

      context 'when block yields to falsy value' do
        def_service do
          def execute!
            result { false }
          end
        end

        it { is_expected.to be_failure }
        its(:result) { is_expected.to be(false) }
      end

      context 'implicit success' do
        def_service do
          def execute!
            :result
          end
        end

        it { is_expected.to be_success }
        its(:result) { is_expected.to eq(:result) }
      end

      context 'implicit failure' do
        def_service do
          def execute!
            nil
          end
        end

        it { is_expected.to be_failure }
        its(:result) { is_expected.to be(nil) }
      end
    end

    describe '#execute!' do
      def_service do
        def execute!
          success!
        end
      end

      it 'automatically becomes private' do
        expect{ build_service.execute! }.to raise_error(/private method `execute!'/)
      end
    end

    describe '.call and .[] helpers' do
      def_service do
        attributes :arg

        def execute!
          arg
        end
      end

      specify '.call' do
        service = service_class.(:foo)
        expect(service).to be_executed
      end

      specify '.[]' do
        result = service_class[:foo]
        expect(result).to eq(:foo)
      end
    end

    describe 'service execution delegation' do
      def_service do
        attributes :arg

        def execute!
          arg * 2
        end
      end

      let(:other_service_class) do
        klass = service_class

        Class.new(Excom::Service) do
          attributes :arg

          define_method(:execute!) do
            ~klass.(arg)
          end
        end
      end

      specify ':result can be delegated via ~@ method' do
        other_service = other_service_class.(5)

        expect(other_service).to be_success
        expect(other_service.result).to be(10)
      end
    end
  end
end
