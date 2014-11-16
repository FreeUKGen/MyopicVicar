class ManageSyndicatesActiveMembersConstraint
 
     def self.matches?(request)
      request.query_parameters['option'] ==  'Review Active Members'
     end
  end
 
 