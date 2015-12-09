class ContactsNameConstraint
 
     def self.matches?(request)
       request.query_parameters['option'] == 'List by Name'
     end
  end