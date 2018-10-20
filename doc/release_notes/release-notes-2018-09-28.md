__FreeREG | Release Notes__
  =======================
  28-09-2018

  __New Features__
  ----------------

  * None


  __Improvements__
  ----------------

  * Added a button to "Initialize Multiple Image Groups" in the Image Server Group management options, in order to save time when marking (Issue 1600).
  * Changed the field names on Edit Image Source, to read "Year" rather than "Date" to avoid confusion (Issue 1132)


  __Fixes__
  ---------

  * Fix deployed for (Issue 1126) which was kicking a small number of users back to the main search page when doing a search, without any parameters being saved.  The fix was made at the MongoDB configuration level, by changing the `write` settings.


  __Change Log__
  ----------------

  Detailed release notes below, listing all commit messages for this release.

* issue #1600 - Initialize Multiple Image Groups (list unallocated groups only)
* Remove notice of search issue
* issue #1600 - Initialize Multiple Image Groups
* issue #1132 - 117142829 confusing field name on edit image source screen
* Added notice message to Search page, about ongoing search issues

  
