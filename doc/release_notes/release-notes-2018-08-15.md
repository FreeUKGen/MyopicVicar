__FreeCEN2 | Release Notes__
=======================
15-08-2018

__New Features__
----------------

* We have started to document each of our releases, and have added a Release Notes folder in our github repository, for easier access.  Release notes can be found at [MyopicVicar / doc / release_notes](https://github.com/FreeUKGen/MyopicVicar/tree/freecen_parsing/doc/release_notes), or in the same folder of your own local clone.

__Improvements__
----------------

* Updated robots.txt file to improve Adsense & Google Indexing coverage
* Added Sitemap at /sitemap.txt to improve Google Indexing coverage and aid bot crawling
* Added FC2 to Google Webmaster Tools / Google Search console, for increased control over Indexing, crawl error monitoring, and other Google product related issues.

__Fixes__
---------

* Added default Errbit parameters to config/errbit.config.yml to avoid Airbrake errors in local clones. 


__FreeREG | Release Notes__
=======================
15-08-2018

__New Features__
----------------

* We have started to document each of our releases, and have added a Release Notes folder in our github repository, for easier access.  Release notes can be found at [MyopicVicar / doc / release_notes](https://github.com/FreeUKGen/MyopicVicar/tree/master/doc/release_notes), or in the same folder of your own local clone.

__Improvements__
----------------

* In 'Create New Register', Submit button styling was poor and not very accessible/user friendly.  Improved appearance in line with the rest of the website theme. (Issue 940)  


__Fixes__
---------

=======
* Fix deployed for NoMethodError caused by an undefined person_role (Issue 1515)
* Fix deployed for image server NoMethodError caused by undefined 'deletion_permitted?' (Issue 1541)
* Fix deployed for image server NameError caused by uninitialised constant (Issue 1512)
