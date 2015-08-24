class MyFilesSelectionConstraint
 
     def self.matches?(request)
       request.query_parameters['option'] == 'Review Specific Batch'
     end
  end