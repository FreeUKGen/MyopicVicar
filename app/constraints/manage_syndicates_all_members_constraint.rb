class ManageSyndicatesAllMembersConstraint
 
     def self.matches?(request)
       request.query_parameters['option'] ==  'Review All Members'
     end
  end
  