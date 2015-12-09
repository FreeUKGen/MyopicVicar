class ContactsIdentifierConstraint
 
     def self.matches?(request)
       request.query_parameters['option'] == 'List by Identifier'
     end
  end