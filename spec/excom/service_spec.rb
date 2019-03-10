require 'spec_helper'

RSpec.describe Excom::Service do
  describe 'args' do
    def_service do
      args :foo, :bar
      opts :baz, :bak
    end

    describe 'inheritance' do
      let(:inherited_service_class) do
        Class.new(service_class) do
          args :foobar
          opts :bazbak
        end
      end

      it 'inherits args and opts list' do
        expect(service_class.args_list).to eq [:foo, :bar]
        expect(service_class.opts_list).to eq [:baz, :bak]
        expect(inherited_service_class.args_list).to eq [:foo, :bar, :foobar]
        expect(inherited_service_class.opts_list).to eq [:baz, :bak, :bazbak]
      end

      specify 'reader helpers' do
        base_service = service_class.new
        inherited_service = inherited_service_class.new

        expect(base_service).not_to respond_to :foobar
        expect(base_service).not_to respond_to :bazbak
        expect(inherited_service).to respond_to :foobar
        expect(inherited_service).to respond_to :bazbak
      end
    end

    context 'when correctly initialized' do
      it 'sets service args and opts' do
        service = build_service(1, baz: 2)

        expect(service.foo).to eq 1
        expect(service.bar).to be nil
        expect(service.baz).to eq 2
        expect(service.bak).to be nil
      end
    end

    context 'when too many args' do
      it 'fails with an error' do
        expect{ build_service(1, 2, 3) }.to raise_error(ArgumentError)
      end
    end

    context 'when invalid opts' do
      it 'fails with an error' do
        expect{ build_service(1, 2, paw: 'wow') }.to raise_error(ArgumentError)
      end
    end

    describe 'opts resolution' do
      it 'sends unkown options to args, if there is place for it' do
        service = build_service(1, baz: 2, paw: 'wow')
        expect(service.foo).to eq 1
        expect(service.bar).to eq(paw: 'wow')
        expect(service.baz).to eq 2
      end
    end

    describe '#with_args' do
      let(:service) { build_service(1) }

      it 'generates a new service with replaced args' do
        args_service = service.with_args(2, 3)
        expect(service.foo).to eq 1
        expect(args_service.foo).to eq 2
        expect(args_service.bar).to eq 3
      end

      it 'clears execution flags' do
        service.execute
        expect(service.with_args(2, 3)).not_to be_executed
      end
    end

    describe '#with_opts' do
      let(:service) { build_service(baz: 1) }

      it 'generates a new service with merged opts' do
        opts_service = service.with_opts(bak: 2)
        expect(opts_service.baz).to eq 1
        expect(opts_service.bak).to eq 2
      end

      it 'clears execution flags' do
        service.execute
        expect(service.with_opts(bak: 2)).not_to be_executed
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
      its(:result) { is_expected.to be :result }
    end

    describe '#failure' do
      subject(:service) { build_service.execute }

      def_service do
        def execute!
          failure { :errors }
        end
      end

      it { is_expected.to be_failure }
      its(:result) { is_expected.to be :errors }
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
        its(:result) { is_expected.to eq :result }
      end

      context 'when block yields to falsy value' do
        def_service do
          def execute!
            result { false }
          end
        end

        it { is_expected.to be_failure }
        its(:result) { is_expected.to be false }
      end

      context 'implicit success' do
        def_service do
          def execute!
            :result
          end
        end

        it { is_expected.to be_success }
        its(:result) { is_expected.to eq :result }
      end

      context 'implicit failure' do
        def_service do
          def execute!
            nil
          end
        end

        it { is_expected.to be_failure }
        its(:result) { is_expected.to be nil }
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
        args :arg

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
        expect(result).to eq :foo
      end
    end

    describe 'service execution delegation' do
      def_service do
        args :arg

        def execute!
          arg * 2
        end
      end

      let(:other_service_class) do
        klass = service_class

        Class.new(Excom::Service) do
          args :arg

          define_method(:execute!) do
            ~klass.(arg)
          end
        end
      end

      specify ':result can be delegated via ~@ method' do
        other_service = other_service_class.(5)

        expect(other_service).to be_success
        expect(other_service.result).to be 10
      end
    end
  end
end
