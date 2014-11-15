class MyFilesAscendingUploadConstraint
 
     def self.matches?(request)
       request.query_parameters['option'] == "List by uploaded date (ascending)"
     end
  end