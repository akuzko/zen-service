require 'spec_helper'
require 'forwardable'

RSpec.describe 'Excom::Plugins::Sentry' do
  Kommand do
    use :sentry, class: 'SpecSentry'
    opts :user, :post

    def run
      post[:deleted] = true
    end
  end

  let(:command) { Kommand(user: user, post: post) }
  let(:user) { {id: 1} }
  let(:post) { {author_id: 1, outdated: false} }

  describe 'simple case' do
    Sentry do
      extend Forwardable
      def_delegators :command, :user, :post

      def execute?
        user[:id] == post[:author_id]
      end
    end

    context 'when sentry allows execution' do
      it 'executes successfully' do
        expect(command.execute).to be_success
        expect(command).to be_executed
        expect(post[:deleted]).to be true
      end
    end

    context 'when sentry declines execution' do
      let(:user) { {id: 2} }

      it 'denies execution' do
        expect(command).not_to receive(:run)
        expect(command.execute).not_to be_success
        expect(command.status).to be :denied
      end
    end
  end

  describe 'advanced usage' do
    Sentry do
      extend Forwardable
      def_delegators :command, :user, :post

      deny_with :unauthorized do
        def execute?
          user[:id] == post[:author_id]
        end

        alias publish? execute?
      end

      deny_with :unprocessable_entity do
        def execute?
          !post[:outdated]
        end
      end
    end

    context 'when denied with first reason' do
      let(:user) { {id: 2} }

      it 'denies execution with proper reason' do
        expect(command).not_to receive(:run)
        expect(command.execute).not_to be_success
        expect(command.status).to be :unauthorized
      end
    end

    context 'when denied with second reason' do
      let(:post) { {author_id: 1, outdated: true} }

      it 'denies execution with proper reason' do
        expect(command).not_to receive(:run)
        expect(command.execute).not_to be_success
        expect(command.status).to be :unprocessable_entity
      end
    end

    describe '#as_json' do
      let(:post) { {author_id: 1, outdated: true} }

      it 'returns a permissions hash' do
        expect(command.sentry.as_json).to eq(
          'execute' => false,
          'publish' => true
        )
      end
    end
  end
end
