__FreeCEN2 | Release Notes__
  =======================
  14-09-2018

  __New Features__
  ----------------

  * -


  __Improvements__
  ----------------

  * Added further statistics to our Transcriber Statistics page https://freecen2.freecen.org.uk/userid_details/transcriber_statistics (Management / Technical staff only), including New Registrations, and other percentage stats for transcriber activity. (Issue 424)
  * Added syndicate (name) details to email notification of user re-assignment (Issue 505)  


  __Fixes__
  ---------

  * Updated Errbit errbit.rb config file to catch errors where a config file does not exist (provides the app with default params to run)


  __Change Log__
  ----------------

  Detailed release notes below, listing all commit messages for this release.


* Converted percentage values to floating points
* Created separate methods for more complex variable calculations for statistics page
* Corrected variable checking user signup date
* Closed method with end, causing error
* Remove error causing variable
* Add method to calculate record percentage and test mongo  selector is working
* Reset percentage method to remove error
* Catch any errors from dividing by zero for total_records calculation
* Added methods to calculate records, along with instance variables to provide statistics
* Added method to calculate user signups in the last 30 days
* Added method to calculate user signups in the last 90 days
* Added new statistics instance variables to userid_details_controller and populated transcriber statistics view
* Added release note for 30-08-2018
* Updated Errbit to catch error if config file does not exist
* Added new syndicate name to change of syndicate email notification



__FreeREG | Release Notes__
  =======================
  14-09-2018

  __New Features__
  ----------------

  * -


  __Improvements__
  ----------------

  * Added further statistics to our Transcriber / Open Data Statistics page https://www.freereg.org.uk/userid_details/transcriber_statistics (Management / Technical staff only), including New Registrations, and other percentage stats for transcriber activity. (Issue 43) 
  * Improvements made to rationalise the secondary search date usage, given the new fields that have been added (Issue 1568)
  * Finalisation of features added for (Issue 1484), Multiple Completed Group Selection.



  __Fixes__
  ---------

  * Fix deployed for (Issue 1101), where a user had reported a problem with the online edit when correcting transcription errors.
  * Fix deployed for (Issue 1566), where an edited entry still displayed as the previous version in the summary page 
  * Fix deployed for (Issue 1575), where the online edit facility did not update the year field.
  * Fix deployed for (Issue 1572), where the "Report a Problem" button stopped working due to formatting changes.
  * Fix deployed for (Issue 1569), NoMethodError reported by Errbit related to the image server.
  * Fix deployed for (Issue 1585), NoMethodError reported by Errbit where the accept / allocate request did not update the ImageServerGroup and ImageServerImage status.
  * Fix deployed for (Issue 1570), ActionController::UrlGenerationError: No route matches error reported by Errbit.
  * Fix deployed for (Issue 1128), where there was no scroll bar showing on the "Select Syndicate" window.
  * Fix deployed for (Issue 1127) where a re-assigned image group was showing the old UserID. 


  __Change Log__
  ----------------

  Detailed release notes below, listing all commit messages for this release.

* rounded percentage statistics to 2 decimal places
* Converted percentage values to floating points
* Created separate methods for more complex variable calculations for statistics page
* Added variables to transcriber statistics method, and new methods for stats calculations
* Added new transcriber statistics on statistics view page
* issue #1128 - no scroll bar on select syndicate window
* issue #1127 - reassigned image group shows old userid
* issue #1585 - accept allocate request does not update ImageServerGroup and ImageServerImage status
* Found an end case of dates that needed fixing
* issue #1484 - fix crash
* revert diagnostics
* fix table formatting
* date change corrected
* fix nil search date in search record creation
* issue #1570 - ActionController::UrlGenerationError
* address issue 1575
* add extra year tests
* no message
* fix report a problem button
* Add comment on zero entry
* Forgot one could not update a search date as it is part of the shard key
* Error in adjustment of transcript dates
* Addresses 1566 and 1568 as well
