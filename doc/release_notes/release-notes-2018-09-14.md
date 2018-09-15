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

  
