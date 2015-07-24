# FreeREG 2 roadmap

This is a roadmap for the development of the FreeREG2 software. Each release is specified to benefit a particular actor and outlines the high-level features or areas we expect to deliver or address for them. Not listed are the data or documentation changes that need to be made in parallel with the software features being developed.

Software components. Mongodb, Ruby on Rails, Refinery, GitHub
Project Management. Agile software development process using scrum/sprint and GigHub 

Version numbers refer to releases of the FreeREG 2 (FR2) project.
Weekly software updates deployed during a version development.
Target completions are based on team of two volunteer developers (one focussed on WinFreeREG) and 8 weeks contract programming support per year.

Versions 1.1 to 1.3 are designed to get a system working so that FreeREG1 can be frozen.  At the completion of 1.3 all work done in FreeREG1 can then done through FreeREG2.  Further versions are replacements for other FreeREG processes, such as the images server and data entry, which are not now integrated, and  enhancements.

## Version 1.0 Set up basic website and database (Jan 2015) (Completed)

### Targeted actors

Managers and Free UK Genealogy staff

### Features

- MPN Master Placenames Collection
- MCN (Master Churches Collection)
- SC list (Syndicate coordinators Collection)
- CC list (County coordinators collection)
- UserID list (Users Collection)
- System Administrator Ability to manage collections
- All private functions behind security
- Tools to manage above collections
- Feedback collection
- Comments collection
- Documentation Repository
- Attic Access
- Basic usage statistics
- Server and Database monitoring tools
- Application error reporting system

### Changes required in order to effect release

- F1 must not update these lists.
- Changes to the above lists in F1 by CCs to these records to be frozen.
- John Pingram (Executive member responsible for Coordinators/Syndicates) and Mick Claxton (Executive member responsible for Data) to be involved.
- EricB appointed Manager of Places.

### Post release activities

- EricD to introduce John Pingram (Executive member responsible for Coordinators/Syndicates) and Mick Claxton (Executive member responsible for Data) to v1.0 system.
- New UserIDs will need to be entered into F2.

## Version v1.1 Search of full database available on server cluster (April 2015) (Completed)

### Targeted actors

Researchers

### Features

- Supercool's design implemented across the public facing pages
- Direct access to search
- Search function stable under load with multiple servers
- Adverts are served and click-tracking works
- Donations page
- Search capabilities at least as good as FR1
- Nearby places search capability added
- Access to automated information on Database Contents
- Support to tablets
- Initial support for Smartphones
- About information
- Contact us capability
- Report data errors/problems
- Login in ability
- Simple navigation
- Information about the search
- Capability to Revise search
- Multi-server deployment 
- Daily update of database

Researcher registration, and the extra features associated with being registered, are not part of this release.

## Version v1.2 Management Functions (July 2015) (Completed)

### Targeted actors

County coordinators and syndicate coordinators.

### Features
 Manage their teams and control the meta data of the database as well as the quality of the data for their teams/counties

- syndicate coordinator can review/add/delete/disable transcribers to their syndicate using variety of  displays; lists by all/active/name/email address/userid 
- Add information to profile of transcribers
- Review work of their transcribers, errors and all batches they have loaded. multiple access means by errors/filename/date of load/userid/
- send out password reset request
- county coordinators can access all/active/specific places in their county. Add/Edit information about the Place. 
- Add Churches to the place. Add/edit information about the church. 
- Add Registers to a Church. Add/edit information about the register.
- Review batches loaded to a register. (They will have access to all batches by all transcribers for all syndicates for THEIR county)
- Relocate(rename) a batch to a different register/church/place.
- Add/Edit information about the batch.
- Review errors and contents of batch
- Correct errors in a batch on-line
- Edit a record in a batch on-line
- Add a record to a batch on-line
- Download a batch
- Batches changed on-line will not be overwritten by a file reload

- Both SC and CC to have access to their own batches and profile

## Version 1.3 Transcriber Access (Sept 2015)

### Targeted actor

Transcribers

### Features

- Transcribers can log into the system
- Review and edit their profile.
- Review files they have uploaded either directly or through FR1
- Review and correct errors on-line
- Review and add/change records on-line (This will not be an on-line transcription tool); enables a missed entry to be added or one changed if better understanding of the content has occurred
- Upload a file into FR2 for batch processing.
- Transcriber registration process
- Simple WinFreeREG access to FR2
- On-line help and documentation

## Version 1.4 Search Engine Enhancements (Jan 2016)

### Targeted actor

Researchers

### Features

 - UCF Support in search engine
 - Better support to smart phones
 - Researchers can register for free to get access to extra facilities.
 - Saved Search feature are accessible to registered users. 
 - Wild card support in search engine
 - Maternal birth name search
 - Double barrelled surnames
 - Add processing indicator to inform user that search is proceeding
 - Avoid gateway time-out
 - Enhanced tips and documentation


## Version 1.5 (April 2016)

### Targeted actor

Coordinators

### Features 

- RAP a system to manage work in progress and available for transcription
- GAP a system to Gaps in Register information.
- Error and usage reports
- Enhanced and consistent validation
- Integrate Image Server
- All images to match Register records.
- Transcribers to select from RAP and get permission from SC.
- Upload images into F2.


## Version 1.6 (July 2016)

### Targeted actor

Transcribers

### Features

- WinFreeREG customized to use full FR2 features
- Emailing of CC, SC and Transcribers.
- Mail-groups.
- Image management for work flow management

## Version 1.7 (Sept 2016)

### Targeted actor

Researchers

### Features 

- GAP integrated with DAP
- Provide database statistics
- Researchers can subscribe to receive emails when registers change.
- Researchers can leave bouquets


## Features to be included but not yet added to schedule

- Report generator.
- CCs and SCs can customise the DAP and RAP.
    
- On-line data entry
    - Front end processor of transcriptions, perhaps being an incorporation of WinFreeReg.
    - Training module, with video?, needed.

- Integrate searches with FreeCEN and FreeBMD 
    - Researchers can record where they have seen entries in the other projects.
   