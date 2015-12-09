class ContactsDateConstraint
 
     def self.matches?(request)
       request.query_parameters['option'] == 'List by Posted Date (ascending)'
     end
  end