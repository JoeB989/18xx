# frozen_string_literal: true

require_relative '../../bot'

module Engine
  class Bot1870 < Engine::Bot
    def roi_value(company, cost)
      # TODO: generalize city bonus in private company properties instead of custom code in each game
      city_bonus =
        case company[:sym]
        when 'SCC'
          1
        when 'GSC'
          2
        else
          0
        end
      extra_share_revenue = city_bonus * 6 * 5 # dumb: assume 5 payouts on 6 shares

      super(company, cost) + extra_share_revenue
    end
  end
end
