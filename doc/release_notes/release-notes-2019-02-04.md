__FreeCEN2 | Release Notes__
  =======================
  04-02-2019

  __New Features__
  ----------------

  * None


  __Improvements__
  ----------------

  * Added improved adblock detection with Javascript and added hyperlink to donation banner ads - Issue 395
  * Added “Last Updated” Section to communicate when the database was updated, as with FreeCEN1 - Issue 372
  * Enabled Google Analytics Tracking of Donation buttons and adblock donation banner - Issue 219 



  __Fixes__
  ---------

  * Fix deployed for Issue 491 - search crashes (Error - ActionController::UrlGenerationError: No route matches {:action=>"show", :controller=>"search_queries", :id=>nil}) 


  __Change Log__
  ----------------

  Detailed release notes below, listing all commit messages for this release.


* Update image path to be correct on remaining pages
* Correct indentation
* Remove comments for banner ads in dev mode
* Remove asset_path helper and use png prefix
* Update to use asset_path helper
* Update asset path
* Update asset path
* Update all asset paths with fingerprints
* Added description for FreeCEN utility collection
* Added spec for FreecenUtiility model
* Added FreeCEN2 updated date in database coverage page
* Change image path format
* Change asset path format
* Undo display:none removal for testing, and change image_tag assets/png path
* Change ads.js location to public folder to work in production
* Testing image rendering in production
* Undo last commit
* Enable serving of static files in production.rb
* Changed image tag, added logs, removed JS application tag
* Remove old adblock background image and create JS function
* Make donations into class rather than id
* Add new adblock image to all pages with banners
* Add JS conditionals to remove CSS class if adblock detected
* Add JS to application.html.erb head
* Add JS to asset initializer to precompile
* Make image/link invisible by default
* Add image/link combo to header for donations
* Add JS to help detect adblockers
* Refactor to use the return of the conditional for variable assignment
* Fix for Issue 491 - remove redundant case statements
* Initial commit
