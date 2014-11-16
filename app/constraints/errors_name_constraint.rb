class ErrorsNameConstraint
 
     def self.matches?(request)
       request.query_parameters['option'] == 'List by Number of Errors then Filename'
       end
  end