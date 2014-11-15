class ErrorsNameConstraint
 
     def self.matches?(request)
       request.query_parameters['option'] == 'List by number of errors then name'
       end
  end