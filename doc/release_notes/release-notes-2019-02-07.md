__FreeREG | Release Notes__
  =======================
  07-02-2019

  __New Features__
  ----------------

  * None


  __Improvements__
  ----------------

  * Completed major Software update for FreeREG (Issue 1386)
  * Added message to those blocking adverts (Issue 41)
  * Moved cookie banner to bottom of screen, for better UX (Issue 1787)
  * Changed cookie banner colours to match FreeREG colour scheme (Issue 1748)

  __Fixes__
  ---------

  * Fix deployed for Issue 1167 (Messages not being accessible)
  * Fix deployed for Issue 1827 ([development][search_queries#reorder] message: Validation of SearchQuery failed. summary:)
  * Fix deployed for Issue 1831 ([development][site_statistics#show] undefined method `interval_end' for nil:NilClass)
  * Fix deployed for Issue 1829 ([development][sources#index] undefined method `count' for #<Source:0x000000081cc7c008>)
  * Fix deployed for Issue 1767 ([production][countries#edit] NoMethodError: undefined method `country_select' for #<SimpleForm::FormBuilder:0x000000081b190ff0>)
  * Fix deployed for Issue 1520 ([production][freereg_contents#place] ActionController::RedirectBackError: No HTTP_REFERER was set in the request to this action)
  * Fix deployed for Issue 1768 ([production][contacts#report_error] Mongoid::Errors::DocumentNotFound: message: Document(s) )
  * Fix deployed for Issue 1753 ([production][search_queries#show] ArgumentError: comparison of BSON::Document with BSON::Document failed)
  * Fix deployed for Issue 1582 ([production][freereg1_csv_files#destroy] NoMethodError: undefined method `file_and_entries_delete' for nil:NilClas)
  * Fix deployed for Issue 1576 (Unallocate Image Group not working)
  * Fix deployed for Issue 1176 (Cannot Create Image Groups)


  __Change Log__
  ----------------

  Change log listing all commit messages for this release.


* Added methods but only for testing purposes
* test fix
* Fix #1827
* Update cookie banner colours
* Issue #41 - uncomment code for dev environment
* Removed async property from adsense script tag
* Add CSS to display:none by default and added image tag to header banner
* Add javascript function to detect adblock
* Trial fix for #1167
* Added javascript file for adblock detection
* Added adblock background image - header-donate.png
* Fix #1821
* Update with tag manager
* Fix #1174
* Catch socket timeout
* Fix #1797
* Layout correction
* Add rubocop gem
* rebase master
* Hold
* Remove whitespace
* Fixes #1777 - Adds Rubocop to Gemfile
* Dock the cookie banner to the bottom of the page
* Make cookie banner larger
* Fixes #1748 - amend cookie banner to match FreeREG house colours
* Fix #1173
* Changed recipient system to comment_only
* Fix the return after confirmation
* Deal with nil issues
* Fix #1798
* test
* Missed a link
* Fix #1799 crash condition
* Complete and remove diags
* breadcrumbs
* Update sources_controller.rb
* diags added
* Augment by adding link to sources from regiater
* Fix #1801
* Update source.rb
* Update source.rb
* Update source.rb
* test version 2
* test version
* First cut of fixes
* Fix 1795 breadcrumbs
* Fix #1168 Missing parameter
* The vino fix
* Revert "test version"
* This reverts commit 70b7d5e7869d6e5f281a3bd6fb11ddba37b05a61.
* test version
* diag
* spelling error
* Mongo added a Regexp class!!
* new example
* Tidy up search query code
* https
* Do not titleize empty records
* Update userid_detail.rb
* Allow for no assignment id
* Individual selection has names need to strip them out
* Fix #1680  too large a number
* Revert "Try a fix for invalid date"
* This reverts commit 3920bc45d66a1514e9ba4637a3419b7021557a7e.
* Try a fix for invalid date
* key? not keys?
* add diagnostic
* hash must exist
* Fix typing error
* 2 message needed changing for mentioning test3
* Update send_message.html.erb
* add test3 check
* Fix 1162
* Update delete_or_archive_old_messages_feedbacks_and_contacts.rb
* version2 still just documenting what will happen
* Increase results
* Fix latest suggestion on issue 1764
* Remove log diagnostics
* Fix #1786 only members can access feedbacks
* Fix #1785
* Fix #1784
* Fix #1764
* Fix #1775
* Fix #1163
* Update sessions_controller.rb
* Use the refinery controllers
* Update FreeCEN link in README
* Add release notes link to README
* Update userid_detail.rb
* Use ugly bypass of the issue 1774
* Update image_server_group.rb
* Remove existing 'then' on multi-line if statement
* Fixes #1598 - Replace .empty? & .length == 0 check with .blank? method on country.rb
* Update user.rb
* remove scribe model and controllers
* Update transreg_csvfiles_controller.rb
* reverse cookie directive
* dummy def require_cookie_directive
* Completion of conversion
* correct upload
* update source controller
* finishes as far as search queries
* Up to and including Freereg1_csv controllers
* Up to contact controller
* add pre-seleted value
* additional hold
* Hold