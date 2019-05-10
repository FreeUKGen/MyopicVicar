Setting Up New Application Using Myopicvicar Code Base:

The myopicvicar code base is multi modal. That is it can be run as different applications using the same code base.

It is currently able to recognize 3 different applications. Additional applications can be added.
  freebmd
  freecen
  freereg


Step 1. Create freeukgen_application.yml
The application initializer reads a field called template_set from a yml file located in the config folder called freeukgen_application.yml that contains the name of the application. An example of the format and layout is contained in freeukgen_application_example.yml

It then configures the specific application using assets from the core, assets_freexxx and the public_site_specific files.

NOTE WHEN MAKING APPLICATION SPECIFIC CHANGES TO ASSETS FOR STYLES, JS, IMAGES ETC THESE MUST BE MADE IN THE ASSETS_FREEXXX FOLDERS. CHANGES TO THE COMMON CORE ASSETS SHOULD BE MADE IN THE ASSETS FOLDER AND THESE WILL AFFECT ALL APPLICATIONS

The initializer creates two fields 1) MyopicVicar::Application.config.template_set containing application name in lower case and 2) MyopicVicar::Application.config.freexxx_display_name which contains the name of the application in CamelCase. The models can use these. Controllers and views can access 3 methods appname, appname_downcase and appname_upcase for ease of typing.

Step 2. Create database.yml

  You can base this on the database.example.yml

Step 3. Create errbit.yml
  On https://errbit.freeukgen.org.uk/ create a new

Step 4. Create mongo_config.yml

Step 5 Create mongoid.yml

Step 6. Clone the myopicvicar code base
 into the folder from which you will run the application server

Step 7. Copy the files created in steps 1-5 into the config folder

Step 8 Start your server


