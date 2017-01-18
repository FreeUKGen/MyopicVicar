class EmendationRulesController < ApplicationController

  def index
    @emendation_rules_replacements = EmendationRule.distinct('replacement')
  end

end
