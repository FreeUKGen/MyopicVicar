__FreeCEN2 | Release Notes__
=======================
01-08-2018

__New Features__
----------------

* Errbit - the Open Source Error catcher has now been added to all of our FreeCEN2 servers which will help us to spot and debug issues more effectively (Issue 493)

__Improvements__
----------------

* None

__Fixes__
---------

* Fixed a bug which was preventing users from signing up, and also preventing existing users from resetting their passwords. (Issue 499)
* Fixed an issue with our Adsense code, in which two ads on our website had the wrong publisher ID from an old account. (Issue 425)



__FreeREG | Release Notes__
=======================
01-08-2018

__New Features__
----------------

* Flexible CSV record format - we have recently extended the number of fields in our database and made the order of these fields flexible.  Features include:
 * Many more fields are now available — information that you used to put in the Notes field is likely to have its own field
 * You can use as many (or as few) of the fields as you need
 * You can have the fields in whatever order works best for your register
 
 
 __Improvements__
 ----------------

 * Added the ability to select multiple submitted groups as complete for Syndicate Coordinators (similar functionality to be added later for Country Coordinators) (Issue 1484)


__Fixes__
---------

* Fixed an issue where render and/or redirect were being called multiple times in register (Issue 1493)
* Fixed an issue which triggered an 'undefined method' error for 'get_sorted_group_name' on ImageServer (Issue 1490)
* Fixed an issue caused by bots navigating past the login area triggering a nomethod error (Issue 1524)
