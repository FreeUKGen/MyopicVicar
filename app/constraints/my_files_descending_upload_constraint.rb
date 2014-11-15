class MyFilesDescendingUploadConstraint
 
     def self.matches?(request)
      p request.query_parameters['option']
       request.query_parameters['option'] == 'List by uploaded date (descending)'
     end
  end