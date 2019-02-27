__FreeCEN2 | Release Notes__
  =======================
  12-10-2018

  __New Features__
  ----------------

  * -


  __Improvements__
  ----------------

  * Added our Volunteer Policy to the signup process (Issue 484) - available here [Volunteer Policy](https://www.freeukgenealogy.org.uk/files/Volunteer-Policy.pdf)


  __Fixes__
  ---------

  * Corrected the Transcription Statistics figures (Issue 424) which was displaying stats related to "New Transcription Agreement" as zero. Viewable at `../userid_details/transcriber_statistics`


  __Change Log__
  ----------------

  Detailed release notes below, listing all commit messages for this release.


* Update link for Volunteer Policy, to pdf file on freeukgen website
* Added :volunteer_policy with acceptance required, to userid_details model
* Added Volunteer Policy checkbox  to transcriber registration view
* Rounded all percentage figures to 2 decimal places
* Changing :new_transcription_agreement to :transcription_agreement since former does not exist on userid_details model




__FreeREG | Release Notes__
  =======================
  12-10-2018

  __New Features__
  ----------------

  *   Added the display of Secondary user roles to user profiles, and made them editable.  Also added a button to display/search users by secondary role, available at `Manage UserIDs > Select Secondary Role` in the Admin Control panel (Issue 1426)
  

  __Improvements__
  ----------------


  * Added our Volunteer Policy to the signup process (Issue 1475) - available here [Volunteer Policy](https://www.freeukgenealogy.org.uk/files/Volunteer-Policy.pdf)
  * Image Groups which were marked "Completed" or "Transcribed" can now be changed (were previously locked after marked complete) (Issue 1544)


  __Fixes__
  ---------

  * Fix made to correct a data error (blank field), for (Issue 1604) which was preventing a Coordinator from accessing the `manage_counties/manage_images` path for `WRY` to manage images.


  __Change Log__
  ----------------

  Detailed release notes below, listing all commit messages for this release.


* Updated release_notes
* Created release note for 28-09-18
* Removed duplicate from gitignore
* Created secondary_roles.html.erb to display users
* Created secondary.html.erb view
* Added secondary_roles method to controller
* Added secondary_role method to model
* Added new options to lib/userid_role.rb
* Updated routes for new secondary_role pages
* Added input fields to form.html view (Create User & Edit User pages), and added check in userid_detail.rb model to remove auto added blank fields to secondary role, caused by include_hidden: false option in form input
* Added display of secondary_role into my_own.html.erb View - viewing profile from -Profile- option
* Added display of secondary_role into show.html.erb - viewing profile from Browse UserIDs
* Update gitignore for cloud9
* Added volunteer policy checkbox to transcriber registration page, for Issue #1475
* Added :volunteer_policy to userid_details model, for Issue#1475
* issue #1604 - add log
* Added start_dbs to gitignore on cloud9
* Update gitignore to exclude /mongod for cloud9
* issue #1604 - Error Message at /manage_counties/ at Manage Images Selection
* issue #1544 - Allow "Completed" and "Transcribed" image groups to be
