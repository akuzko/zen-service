require 'spec_helper'

RSpec.describe Excom::Command do
  describe 'args' do
    Kommand do
      args :foo, :bar
      opts :baz, :bak
    end

    describe 'inheritance' do
      let(:inherited_kommand) do
        Class.new(kommand_class) do
          args :foobar
          opts :bazbak
        end
      end

      it 'inherits args and opts list' do
        expect(kommand_class.args_list).to eq [:foo, :bar]
        expect(kommand_class.opts_list).to eq [:baz, :bak]
        expect(inherited_kommand.args_list).to eq [:foo, :bar, :foobar]
        expect(inherited_kommand.opts_list).to eq [:baz, :bak, :bazbak]
      end

      specify 'reader helpers' do
        base_command = kommand_class.new
        inherited_command = inherited_kommand.new

        expect(base_command).not_to respond_to :foobar
        expect(base_command).not_to respond_to :bazbak
        expect(inherited_command).to respond_to :foobar
        expect(inherited_command).to respond_to :bazbak
      end
    end

    context 'when correctly initialized' do
      it 'sets command args and opts' do
        command = Kommand(1, baz: 2)

        expect(command.foo).to eq 1
        expect(command.bar).to be nil
        expect(command.baz).to eq 2
        expect(command.bak).to be nil
      end
    end

    context 'when too many args' do
      it 'fails with an error' do
        expect{ Kommand(1, 2, 3) }.to raise_error(ArgumentError)
      end
    end

    context 'when invalid opts' do
      it 'fails with an error' do
        expect{ Kommand(1, 2, paw: 'wow') }.to raise_error(ArgumentError)
      end
    end

    describe 'opts resolution' do
      it 'sends unkown options to args, if there is place for it' do
        command = Kommand(1, baz: 2, paw: 'wow')
        expect(command.foo).to eq 1
        expect(command.bar).to eq(paw: 'wow')
        expect(command.baz).to eq 2
      end
    end

    describe '#with_args' do
      let(:command) { Kommand(1) }

      it 'generates a new command with replaced args' do
        args_command = command.with_args(2, 3)
        expect(command.foo).to eq 1
        expect(args_command.foo).to eq 2
        expect(args_command.bar).to eq 3
      end

      it 'clears execution flags' do
        command.execute
        expect(command.with_args(2, 3)).not_to be_executed
      end
    end

    describe '#with_opts' do
      let(:command) { Kommand(baz: 1) }

      it 'generates a new command with merged opts' do
        args_command = command.with_opts(bak: 2)
        expect(args_command.baz).to eq 1
        expect(args_command.bak).to eq 2
      end

      it 'clears execution flags' do
        command.execute
        expect(command.with_opts(bak: 2)).not_to be_executed
      end
    end
  end

  describe 'execution' do
    describe '#result' do
      subject(:command) { Kommand().execute }

      context 'success with Hash' do
        Kommand do
          def run
            result success: :result
          end
        end

        it { is_expected.to be_success }
        its(:status) { is_expected.to eq :success }
        its(:result) { is_expected.to eq :result }
      end

      context 'success with object' do
        Kommand do
          def run
            result :result
          end
        end

        it { is_expected.to be_success }
        its(:status) { is_expected.to eq :success }
        its(:result) { is_expected.to eq :result }
      end

      context 'implicit success' do
        Kommand do
          def run
            :result
          end
        end

        it { is_expected.to be_success }
        its(:status) { is_expected.to eq :success }
        its(:result) { is_expected.to eq :result }
      end

      context 'fail with Hash' do
        Kommand do
          def run
            result custom_failure: :error
          end
        end

        it { is_expected.to be_failure }
        its(:status) { is_expected.to eq :custom_failure }
        its(:result) { is_expected.to eq :error }
      end

      context 'implicit failure' do
        Kommand do
          def run
            nil
          end
        end

        it { is_expected.to be_failure }
        its(:status) { is_expected.to eq :failure }
        its(:result) { is_expected.to be nil }
      end
    end

    describe '.fail_with' do
      Kommand do
        fail_with :total_failure

        def run
          failure!
        end
      end

      subject(:command) { Kommand().execute }

      it { is_expected.to be_failure }
      its(:status) { is_expected.to eq :total_failure }
    end

    describe '.alias_success' do
      Kommand do
        alias_success :ok

        def run
          result ok: 5
        end
      end

      subject(:command) { Kommand().execute }

      it { is_expected.to be_success }
      its(:status) { is_expected.to eq :ok }
      its(:result) { is_expected.to eq 5 }
    end

    describe '#run' do
      Kommand do
        def run
          success!
        end
      end

      it 'automatically becomes private' do
        expect{ Kommand().run }.to raise_error(/private method `run'/)
      end
    end

    describe '#status' do
      Kommand do
        def run
          status :ok
        end
      end

      let(:command) { Kommand().execute }

      it 'assigns status' do
        expect(command.status).to eq :ok
      end
    end

    describe '.call and .[] helpers' do
      Kommand do
        args :arg

        def run
          arg
        end
      end

      specify '.call' do
        command = kommand_class.(:foo)
        expect(command).to be_executed
      end

      specify '.[]' do
        result = kommand_class[:foo]
        expect(result).to eq :foo
      end
    end
  end
end
