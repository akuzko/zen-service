# frozen_string_literal: true

module Zen
  module Service::Plugins
    module Assertions
      extend Plugin

      private def assert
        if yield
          success! unless state.has_success?
        else
          failure!
        end
      end
    end
  end
end
