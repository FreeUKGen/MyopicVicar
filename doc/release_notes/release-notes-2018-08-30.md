__FreeREG | Release Notes__
  =======================
  30-08-2018

  __New Features__
  ----------------

  * None


  __Improvements__
  ----------------

  * Created a rake task to partially automate and generate our weekly release notes.  Have also added a 'Change Log' section to release notes, showing a list of commit messages for that release.
  * Improvements made to the list batches report by reformatting the report display. (Issue 1089)
  * Improvements made to (Issue 1484) - Multiple Group selection, including the addition of CC acceptance.
  * Improvement made to list provided to coordinators, of processed files (Issue 791) - in the initial list format, the upload date was referenced.  This was changed to the processed date since files can be processed without an upload.


  __Fixes__
  ---------

  * Fix deployed for (Issue 1562) - nil field in DEF fields crashes processor, which was caused by a single trailing ',' in a field definition.  Code added to avoid crashes and display a message to the transcriber.
  * Temporary fix deployed for (Issue 1554) where users were not able to login to the FR website via WinFreeREG.
  * One of our database servers was down for a short time during this sprint - database has since been rebuilt.


  __Change Log__
  ----------------

  Detailed release notes below, listing all commit messages for this release.


* correct helper call
* test for nil field in DEF
* repeat change
* kludge was too soon in code and ineffective
* another kludge
* send dummy id rather than a hash
* remove diags
* add diags
* add diags
* add diags
* present not empty
* clean up of code duplication
* added cludge to avoid sending feedback replies to WinFreeReg
* fix helper on nil condition. Wrong date
* Update rake task to pull git commit messages from current sprint
* Create rake task to automate release notes partially
* initial reformat
* Updated formatting of blank release note fields
* Add release note for 15-08-2018
* Created Release Notes folder & previous release notes

  
