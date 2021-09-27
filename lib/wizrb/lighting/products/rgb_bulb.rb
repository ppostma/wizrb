# frozen_string_literal: true

module Wizrb
  module Lighting
    module Products
      class RgbBulb
        FEATURES = {
          brightness: true,
          color_temp: true,
          color: true,
          effect: true,
          scenes: %i[
            ocean
            romance
            sunset
            party
            fireplace
            cozy
            forest
            pastel_colors
            wake_up
            bedtime
            warm_white
            daylight
            cool_white
            night_light
            focus
            relax
            true_colors
            tv_time
            plantgrowth
            spring
            summer
            fall
            deepdive
            jungle
            mojito
            club
            christmas
            halloween
            candlelight
            golden_white
            pulse
            steampunk
            rhythm
          ]
        }.freeze
      end
    end
  end
end
