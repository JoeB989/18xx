# frozen_string_literal: true

module Engine
  # do the simplest thing that works
  class DumbBot < Bot
    def value_private(company, step, player)
      cost = if step.may_purchase?(company)
               company.value
             else
               player_bids = company.bids.map { |bid| bid if bid.entity == player }.compact
               if player_bids.empty?
                 step.min_bid(company)
               else
                 player_bids[0].price
               end
             end
      if company.reveue.zero?
        200 - cost # dumb: assume the purchase will yield a $100 presidency
      else
        ((company.revenue * 10) / cost) + (cost * 2) # base ROI plus amount can loot from railroad
      end
    end

    def choose_ISR_action
      # return buy or bid or pass
    end
  end
end
