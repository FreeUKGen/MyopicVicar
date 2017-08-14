class  ManageCountiesManageImagesConstraint  
 
     def self.matches?(request)
      request.query_parameters['option'] ==  'Manage Images'
     end
  end
  