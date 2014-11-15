class MyFilesAlphabeticalConstraint
 
     def self.matches?(request)
       request.query_parameters['option'] == 'List by name'
     end
  end