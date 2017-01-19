class EmendationRulesController < ApplicationController

  def index
    @emendation_rules = EmendationRule.sort_by_initial_letter(EmendationRule.distinct('replacement'))
    @alphabet_keys = @emendation_rules.keys
  end

end
