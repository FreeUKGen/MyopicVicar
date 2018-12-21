__FreeREG | Release Notes__
  =======================
  21-12-2018

  __New Features__
  ----------------

  * None


  __Improvements__
  ----------------

  * Issue 1687 - Implemented ability to keep / archive messages, and set them to be destroyed after an expiry period
  * Issue 1728 - Fine tuning of system based on SC usage
  * Issue 1711 - Minor updating of messages_helper.rb
  * Issue 1708 - Minor tweaks to message system 
  * Issue 1149 - Fix deployed for user reported error caused by display code - 124280739 Unable to remove a message from my login page list (Eric)


  __Fixes__
  ---------

  * Issue 1727 - Fix deployed for Unexpected error message when trying to reply to a contact (Staffordshire)
  * Issue 1715 - Fix deployed to revise how we select the people when we say role. Some roles do not pick up expected population eg SC or CC
  * Issue 1716 - Fix deployed for Errbit error - [production][userid_details#new] NoMethodError: undefined method `to_a' for "Wales - Glen Jenkins":String
  * Issue 1702 - Fix deployed to trap Errbit error - [production][image_server_groups#upload_return] NoMethodError: undefined method `source' for nil:NilClass
  * Issue 1707 - Fix deployed for simple form causing error - Errbit - [production][countries#edit] NoMethodError: undefined method `country_select' for #<SimpleForm::FormBuilder:0x000000081b8b8620>
  * Issue 1712 - Fix deployed for typo causing errbit error - [production][image_server_images#destroy] NameError: undefined local variable or method `image_server_image' for #<ImageServerImagesControl
  * Issue 1148 - Fix deployed for user reported error - 124280168 A wrong link after replying to a contact (Eric)



  __Change Log__
  ----------------

  Detailed release notes below, listing all commit messages for this release.


* Update message.rb
* Bad use of case
* Update messages_controller.rb
* Update messages_controller.rb
* Phase1
* Use array not string
* Update correct_image_server_group.rb
* Ready for real time
* pass fix
* Update correct_image_server_group.rb
* Recode upload return and revised rake
* For testing
* Update freereg1_csv_files_controller.rb
* My bad on the zero year method addition accidently deleted this method
* simple form does wierd things with country
* Spelling
* Ready for testing
* Update messages_helper.rb
* second teaks
* tweaks fo SCs
* phase 1 of keep for contacts and feedbacks
* Update breadcrumbs.rb
* Update actions.html.erb
* Updated to reflect different types of messages
* Update messages_controller.rb