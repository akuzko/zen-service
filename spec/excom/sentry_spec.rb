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

  describe 'inheritance' do
    Sentry do
      allow :execute
    end

    it 'inherits sentry class' do
      inherited_kommand = Class.new(kommand_class)
      expect(inherited_kommand.sentry_class).to be SpecSentry
    end
  end

  describe 'simple case' do
    Sentry do
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

    describe '#to_hash' do
      let(:post) { {author_id: 1, outdated: true} }

      it 'returns a permissions hash' do
        expect(command.sentry.to_hash).to eq(
          'execute' => false,
          'publish' => true
        )
      end
    end
  end

  describe 'inline sentry usage' do
    Kommand do
      use :sentry
      opts :user, :post

      def run
        post[:deleted] = true
      end

      def foo
        5
      end

      sentry delegate: [:foo] do
        deny_with :unauthorized

        def execute?
          user[:id] == post[:author_id]
        end

        def foo?
          foo > 0
        end

        alias_method :publish?, :execute?

        deny_with :unprocessable_entity do
          def execute?
            !post[:outdated]
          end
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

    describe '#sentry_hash' do
      let(:post) { {author_id: 1, outdated: true} }

      it 'returns a permissions hash' do
        expect(command.sentry_hash).to eq(
          'execute' => false,
          'publish' => true,
          'foo'     => true
        )
      end
    end
  end

  describe 'helper methods' do
    Sentry do
      allow :execute
      deny :delete

      deny :archive, with: :unauthorized

      deny_with :unprocessable_entity do
        deny :update
      end
    end

    it 'assigns permissions properly' do
      expect(command.can?(:execute)).to be true
      expect(command.can?(:delete)).to be false
      expect(command.can?(:archive)).to be false
      expect(command.can?(:update)).to be false

      expect(command.why_cant(:delete)).to be :denied
      expect(command.why_cant(:archive)).to be :unauthorized
      expect(command.why_cant(:update)).to be :unprocessable_entity
    end

    describe '#sentry' do
      class OtherSpecSentry < Excom::Sentry
        deny :execute
      end

      context 'when klass is used' do
        Sentry do
          def other?
            sentry(OtherSpecSentry).execute?
          end
        end

        specify { expect(command.can?(:other)).to be false }
      end

      context 'when symbol is used' do
        Sentry do
          def other?
            sentry(:other_spec).execute?
          end
        end

        specify { expect(command.can?(:other)).to be false }
      end
    end
  end
end
