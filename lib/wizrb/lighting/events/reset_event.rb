# frozen_string_literal: true

require_relative 'event'

module Wizrb
  module Lighting
    module Events
      class ResetEvent < Wizrb::Lighting::Events::Event
        def initialize
          super(method: 'reset')
        end
      end
    end
  end
end
