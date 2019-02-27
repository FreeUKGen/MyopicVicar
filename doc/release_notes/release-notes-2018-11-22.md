__FreeCEN2 | Release Notes__
  =======================
  22-11-2018

  __New Features__
  ----------------

  * None


  __Improvements__
  ----------------

  * Adblock message (Issue 395) added on all of our Ads to show when users are using an adblocker, to suggest donations in place of having ads  
  * Improvements made to how our ads are displayed  (Issue 506) on mobile devices, adding responsiveness so that they show on tablet screens 
  * Google Tag Manager added (Issue 504) to all FreeCEN2 pages to give us more control over Analytics and code 
  * Email text for new registrations (Issue 542) has been updated to allow coordinators more time to respond to initial signups


  __Fixes__
  ---------

  * Fix deployed for (Issue 522) - Country Coordinator Error, caused by .empty? checks being used in place of .blank? 


  __Change Log__
  ----------------

  Detailed release notes below, listing all commit messages for this release.

* Updated tag manager code
* Added another .blank? check due to NoMethodError and corrected system_administrator typo
* Removed .length check causing error and replaced with .present?
* Remove .length check on nil field which was returning error
* Replace .empty? check with .blank? to account for nil cases
* Add .byebug_history to gitignore
* Removed hard coded user details, replaced with @coordinator values
* Updated email message for new registrations
* Change class name from banner-horz to bnner-horz to avoid Adblock
* Change class name from cen_advert to cen_unit to avoid adblock
* Added box shadow to emphasise top banner ad unit and follow material design guidelines
* Added bg image for donations/adblock, and file path to CSS
* Added asset path helper in CSS, for background image url
* Renamed image from 728x90.png to header-donate.png due to being blocked by Adblock
* Remove redundant <%= display_header %> in header
* Remove display_banner function from bloated application_helper file
* Refactored CSS for site header, made ad and logo more responsive and removed redundant margin from site__header__logo
* Remove redundant margin from site__header__logo
* Moved .adsenseBanner CSS for banner_header function from ruby file (application_helper.rb) into CSS file
* Changed banner ad min-width to width to fix repsonsiveness
* Added a 2 second delay to loading of Adblock Message, so adsense ads load before it
* Added class for adblock background
* Changed JS functoin to target main banner ad, banner_header
* Add flexbox to .adsense_center container to correct centering issues
* Added bnner-horz-secondary class to all google_advert divs, previously empty
* Added CSS for class, bnner-horz-secondary, to make all google_advert units responsive
* Added bnner-horz-secondary class to fullwidth_adsense units, to make fully responsive
* Removed CSS from google_advert and fullwidth_adsense functions, and added to lap_and_up.scss.erb file - making .adsenseBanner units fit to 100% of their outer containers
* Added margins to correct logo placement on tablet/mobile devices
* Add CSS for lower than tablet sizes
* Updated adblock background image
* Added loop to capture all bnner-horz-secondary elements, and changed bg color to green to test asset pipeline
* Added JS for adding class to banner ads for adblock
* Updated image path in SCSS to work with Rails 4
* Added scaling for adblock bg image, for 320px ad widths





__FreeREG | Release Notes__
  =======================
  22-11-2018

  __New Features__
  ----------------

  * None


  __Improvements__
  ----------------

  * None


  __Fixes__
  ---------

  * Fix deployed for Errbit Error, Issue 1652 - Feedbacks typo in path name 
  * Fix deployed for Issue 1139 - Create new message button disappeared 
  * Fix deployed for Errbit Error, Issue 1655 - [image_server_groups#my_list_by_county] NoMethodError: private method `select' called for #
  * Error with too many images, Issue 1140 - rake task written to detect Issue, but Issue still unresolved 
  * Fix deployed for Issue 1069 - Data Manager Batch destroy times out and leaves incomplete status 


  __Change Log__
  ----------------

  Detailed release notes below, listing all commit messages for this release.


* Add checks for absent files
* add no_timeout to cursor
* add process counter
* version 1 of correction rake for evaluation
* version 1 of correction rake for evaluation
* add userid to transfer
* issue #1655 - NoMethodError: private method 'select' called for #<Source:...>
* typo
* correct typo in path name
