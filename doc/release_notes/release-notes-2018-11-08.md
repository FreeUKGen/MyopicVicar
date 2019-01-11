__FreeREG | Release Notes__
  =======================
  08-11-2018

  __New Features__
  ----------------

  * (Not yet live) - Issue 1374, Citation Generator code has been included in our production code, but has not yet been activated. Will be added once permanent URLs have been completed. Developer note - switch included in mongo_config to activated this feature. 


  __Improvements__
  ----------------

  * None


  __Fixes__
  ---------

  * Issue 1631 - Fix deployed for errbit error, unitialized constant SourceProperty::Status#1635
  * Issue 1369 - Fix deployed for Missing images associated with fallback CSS for icons
  * Issue 1605 - Fix deployed for physical file processor crash - code added to improve system log messages if processor crashes, and updated documentation on crashes.
  * Issue 1498 - Fix deployed for Information about "Review batches by filename” 
  * Feedbacks & Reply Communication fixes - a large batch of fixes were deployed related to feedbacks & replies, including:
   * Issue 1516 - Errbit error [production][messages#update] NoMethodError: undefined method include?' for nil:NilClass
   * Issue 1514 - Errbit error [production][messages#create] DocumentNotFound
   * icon that opens issue or pull request in GitHub in new window
   * Issue 1525 - Copy comms-coord email address to replies to contacts 
   * Issue 1526 - Replace “Destroy” button in contacts with an Archive button
   * Issue 1629 - Modify feedback to show display responses
   * Issue 1119 - Cannot reply to feedbacks


  __Change Log__
  ----------------

  Detailed release notes below, listing all commit messages for this release.


* add switch
* Created release note for 29-10-18
* issue #1634 - undefined method 'empty?' for nil:NilClass
* links to show definitely
* links to show
* issue #1631 - unitialized constant SourceProperty::Status
* Update app/views/user_mailer/coordinator_feedback_reply.html.erb
* Update app/views/user_mailer/coordinator_contact_reply.html.erb
* Update app/views/user_mailer/coordinator_contact_reply.html.erb
* Updated reply messages
* add trap to avoid missing attachment
* remove correct routes
* remove list by identifier
* contacts sender_user was an object in messages
* formatting error in message
* same variable name problem in different model
* wrong variable name
* add traps for document existing
* remove diags
* fix register type
* attachment needs adding
* final clean up of contacts and feedbacks(I hope)
* integrate contacts and feedbacks
* tweak reply
* Clean out diags
* add 2 files
* Next phase of feedback cleanup
* Phase 2 feedback
* Phase 1 feeback system cleanup
* multiple redirect
* Add displays for others
* add functionality for achived phase1
* phase1 rewrite
* phase 2 changes
* Initial changes
* wrong variable name
* return to basic index after archive
* contact archiving
* add sender
* forgot the ?
* add secondary
* spelling
* spelling
* added additional links to show
* added additional links to show
* added additional recipients to show
* add additional recipients
* last correction
* add to whom and copies
* sent_messages note plural
* match field types
* field name changed
* delay push
* look up userid
* Use empty array as default
* create empty array
* typo in last commit
* Do not test include for nil array
* Do not include copy message if there are no copies
* Correct userid
* test for nil copies
* correct private call
* Correct active call
* Correct update_attribute call
* Dry the contacts
* sent message recipents
* issue #1625 - Render and/or redirect were called multiple times
* Add contact coordinator copy
* Further cleanup
* initial cleanup
* avoid lookup of coordinator for missing search record or entry
* erb version of fallback
* Added test for recippients and returned if nil
* change url
* Added crash message to logs
* spelling correction
* Make display consistent with documentation
* remove forced processor crash
* better logging test
* use the correct method and remove the other
* Fixing MLA format
* Add extra fields to mla citation
* Fix to allow traverse by tab
* Fix for ArgumentError
* Add citation generator in a clean branch




  
