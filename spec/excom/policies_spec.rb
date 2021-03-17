require 'spec_helper'
require 'forwardable'

RSpec.describe 'Excom::Plugins::Policies' do
  def_service do
    use :policies

    attributes :user, :post

    deny_with :unauthorized do
      def publish?
        user[:id] == post[:author_id]
      end

      def delete?
        publish?
      end
    end

    deny_with -> { :unprocessable_entity } do
      def delete?
        !post[:outdated]
      end
    end

    deny_with StandardError.new('not allowed') do
      def publish?
        user[:id] > 0
      end
    end
  end

  let(:service) { build_service(user: user, post: post) }
  let(:user)    { { id: 1 } }
  let(:post)    { { author_id: 1, outdated: false } }

  describe '#execute' do
    specify do
      expect(service.execute.result).to eq(
        'publish' => true,
        'delete'  => true
      )
    end
  end

  describe '#guard!' do
    context 'when can' do
      specify do
        expect { service.guard!(:publish) }.not_to raise_error
      end
    end

    context 'when can not' do
      context 'when reason is not an exception' do
        let(:post) { { author_id: 2, outdated: false } }

        specify do
          expect { service.guard!(:publish) }.to raise_error(Excom::Plugins::Policies::GuardViolationError, 'unauthorized')
        end
      end

      context 'when reason is an exception' do
        let(:user) { { id: 0 } }
        let(:post) { { author_id: 0, outdated: false } }

        specify do
          expect{ service.guard!(:publish) }.to raise_error(StandardError, 'not allowed')
        end
      end
    end
  end

  describe '#can?' do
    context 'when can' do
      specify do
        expect(service.can?(:publish)).to be(true)
      end
    end

    context 'when can not' do
      let(:post) { { author_id: 2, outdated: false } }

      specify do
        expect(service.can?(:publish)).to be(false)
      end
    end
  end

  describe '#why_cant?' do
    context 'when reason is not a Proc' do
      let(:post) { { author_id: 2, outdated: false } }

      specify do
        expect(service.why_cant?(:delete)).to be(:unauthorized)
      end
    end

    context 'when reason is a Proc' do
      let(:post) { { author_id: 1, outdated: true } }

      specify do
        expect(service.why_cant?(:delete)).to be(:unprocessable_entity)
      end
    end
  end
end
