class ContactsSelectIdentifierConstraint
 
     def self.matches?(request)
       request.query_parameters['option'] == 'Select by Identifier'
     end
  end