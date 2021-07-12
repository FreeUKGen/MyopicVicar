class ManageCountiesReviewAllFreecen2PiecesConstraint
  def self.matches?(request)
    request.query_parameters['option'] == 'Review All Freecen2 Pieces'
  end
end
