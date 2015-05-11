class ManageSyndicatesChangeRecruitingStatusConstraint
 
     def self.matches?(request)
      request.query_parameters['option'] ==  'Change Recruiting Status'
     end
  end
 
  