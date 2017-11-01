require 'spec_helper'

RSpec.describe Excom::Command do
  describe 'args' do
    Kommand do
      args :foo, :bar
      opts :baz, :bak
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
        expect{ Kommand(paw: 'wow') }.to raise_error(ArgumentError)
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

    describe 'opts override' do
      Kommand do
        opts :foo

        def run
          foo * 2
        end
      end

      let(:command) { Kommand(foo: 2) }

      it 'allows to override initialization opts upon execution' do
        expect(command.execute.result).to eq 4
        expect(command.execute(foo: 4).result).to eq 8
        expect(command.foo).to eq 2
      end
    end
  end
end
