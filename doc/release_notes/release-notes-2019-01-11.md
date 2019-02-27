
__FreeCEN2 | Release Notes__
  =======================
  11-01-2019

  __New Features__
  ----------------

  * None


  __Improvements__
  ----------------

  * None


  __Fixes__
  ---------

  * Fix deployed for (Issue 567) FC2 Timing out after a second or two - this was caused by a configuration file on colobus being incorrectly set to 10ms.  File has now been updated. 
  * Fix deployed for Errbit Error (Issue 517)
  * Fix deployed for Errbit Error (Issue 556)
  * Updated an old link on the FC2 databse coverage page, to point to FC1 (Issue 565)


  __Change Log__
  ----------------

  Detailed release notes below, listing all commit messages for this release.

  * Correct link on DB coverage page



__FreeREG | Release Notes__
  =======================
  11-01-2019

  __New Features__
  ----------------

  * None


  __Improvements__
  ----------------

  * Issue 1350 - Transcriber (etc) can contact ExDir, SC, CC, etc via buttons from landing page
  * Issue 1687 - Keep 'Archive' and set messages to be destroyed after expiry period 
  * Issue 1157 - Improvement made to make it more obvious how to locate an attachment in the messaging system 
  * Issue 1726 - Amended text on message to to 'If replying to this message, for security and privacy reasons, please use the message system'
  * Issue 1351 - Added Tickybox to record that a message sent to an individual has been answered by the individual outside the system
  * Issue 1096 - Added check for orphan entries
  * Issue 1747 - Fix deployed for Errbit error - [production][freereg_contents#show_church] NoMethodError: undefined method `county' for nil:NilClass
  * Issue 1746 - Fix deployed for Errbit error - [production][freereg1_csv_entries#create] Mongoid::Errors::InvalidFind: message:
  * Issue 1745 - Fix deployed for Errbit error - [production][image_server_images#move] NoMethodError: undefined method `[]' for nil:NilClass


  __Fixes__
  ---------

  * Issue 1740 - Fix deployed for Errbit error - [production][contacts#create] NoMethodError: undefined method `userid' for nil:NilClass
  * Issue 1743 - Fix deployed for Errbit error - [production][contacts#show] NoMethodError: undefined method `register' for nil:NilClass


  __Change Log__
  ----------------

  Change log listing all commit messages for this release.


* Further text improvements for missing record
* Change text of error message in the light of the use of friendly  urls
* Do not create a image file name  if one already exists in the group
* Update new.html.erb
* Update new.html.erb
* Update delete_or_archive_old_messages_feedbacks_and_contacts.rb
* add config
* Update delete_or_archive_old_messages_feedbacks_and_contacts.rb
* Preliminary version
* Final version
* Update check_image_availability.rb
* Update check_image_availability.rb
* initial version
* Update messages_helper.rb
* tidy up
* trap a condition that should never occur
* Update freereg_contents_controller.rb
* mailer changes
* Revert "mailer changes"
* This reverts commit 72f3eca9f0e60e54938edd60c8bc062be0209d6a.
* mailer changes
* Update check_and_delete_orphan_records.rb
* Update check_and_delete_orphan_records.rb
* Update check_and_delete_orphan_records.rb
* Update check_and_delete_orphan_records.rb
* add sleep option
* Initial rake task
* add comments to communications
* Evaluation version
* remove a stray blank
* Update messages_helper.rb
* Update send_message.html.erb
* Added extra guard cause
* missing coordinator trap
* remove print
* Improve email
* Improve attachment visibility
* Clean up contact/feedback integration
* Fix feedback integration
* review version
* past christmas hold
* Christmas hold
* holding
* phase 1b
* Phase 1a miised a component
* phase 1 
