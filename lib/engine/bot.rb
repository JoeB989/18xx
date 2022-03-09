# frozen_string_literal: true

module Engine
  # base class does the simplest thing that works
  class Bot
    # return buy/bid/pass action in private-auction round
    def private_auction_action(step, player)
      available = step.available.select(&:company?)
      no_bids = available.map { |company| company if company.bids.empty? }.compact

      committed_cash = 0
      my_bids = available.map do |company|
        player_bids = company.bids.map { |bid| bid if bid.entity == player }.compact
        unless player_bids.empty?
          committed_cash += player_bids[0].price
          company
        end
      end.compact

      biddable = available - my_bids
      buyable = available.map { |company| company if step.may_purchase?(company) }.compact
      budget = player.cash - committed_cash # dumb - should reserve some cash for shares

      choose = lambda do |consider|
        choices = consider.max_by do |company|
          next if step.min_bid(company) > budget
          next unless company.bids.empty?

          value_private(company, step, player)
        end.compact

        Engine::Action::Bid.new(player, company: choices[0], price: step.min_bid(choices[0])) unless choices.empty?
      end

      # if we don't have a bid in yet, bid on highest value private with no bids, but don't buy the buyable one
      if my_bids.empty?
        action = choose.call(no_bids - buyable)
        return action if action
      end

      # if there's a high value private with no bids, buy or bid on it if possible
      action = choose.call(no_bids)
      return action if action

      # see if there's a private we want to raise the bid on
      action = choose.call(biddable - my_bids)
      return action if action

      # see if we want to buy the cheap one
      action = choose.call(buyable)
      return action if action

      Action::Pass.new(player)
    end

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
        presidency_value(company, cost)
      else
        roi_value(company, cost) + loot_value(company)
      end
    end

    def presidency_value(_company, cost)
      200 - cost # dumb: assume the purchase will yield a $100 presidency
    end

    def roi_value(company, cost)
      ((company.revenue * 10) / cost) * expected_player_payouts(company)
    end

    def expected_player_payouts(_company)
      4 # dumb guess
    end

    def loot_value(company)
      company.value * 2 # dumb: full amount can loot from railroad
    end

    def bot_action(_round, _player)
      nil # TODO
    end
  end
end
