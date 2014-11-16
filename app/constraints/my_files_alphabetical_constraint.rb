class MyFilesAlphabeticalConstraint
 
     def self.matches?(request)
       request.query_parameters['option'] == 'List by Filename'
     end
  end