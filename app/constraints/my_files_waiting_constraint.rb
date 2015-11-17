class MyFilesWaitingConstraint
 
     def self.matches?(request)
       request.query_parameters['option'] == 'List files waiting to be processed'
     end
  end