class EmendationRulesController < ApplicationController

  def index
    @emendation_rules = EmendationRule.all.to_a
  end

end
