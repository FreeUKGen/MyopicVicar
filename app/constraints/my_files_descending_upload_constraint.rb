class MyFilesDescendingUploadConstraint
 
     def self.matches?(request)
       request.query_parameters['option'] == 'List by uploaded date (descending)'
     end
  end