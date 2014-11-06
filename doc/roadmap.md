# FreeREG 2 roadmap

This is a roadmap for a staged transition from FreeREG1 to FreeREG2. It starts with those with most experience and who can give constructive feedback, working eventually to researchers. This is also basically the same sequence that will be used for new data through transcription to research:

- Managers will set up the basic structure.
- CCs will enter register (and eventually image) information, from which Transcribers will select work.
- Transcribers then upload and SCs monitor their work and performance.
- Eventually we have online data entry.

These phases only refer to the database and changes which affect users.  We can keep adding extra facilities, such as maps, when we like.

## Version 1.0

### Targeted actors

Managers and Free UK Genealogy staff

### Features

- MPN
- MCN (Churches)
- SC list
- CC list
- UserID list

### Changes required in order to effect release

- F1 must not update these lists.
- All changes in F1 by CCs to these records to be frozen.
- John Pingram (Executive member responsible for Coordinators/Syndicates) and Mick Claxton (Executive member responsible for Data) to be involved.
- EricB, if he wants to, to be appointed Manager of Places.
- New UserIDs will need to be entered into F2.

## Version v1.1

### Targeted actors

County coordinators and syndicate coordinators.

We may find it useful to divide the county coordinators into two groups: those who we think will have a quick grasp of thing, and those who will need more guidance. 
We can then roll out the release to these groups in two stages.

### Features

- All records go live.

### Changes required in order to effect release:

- Transcribers will still use F1.
- CCs and SC to be trained and use F2 only.
- Register and Batch records to be checked.
- Register records to be created for data waiting to be transcribed.  (Needed for the RAP and for Transcribers to select.)
- Changed CSV batches will need to be copied across from time to time.  This will be from the Test server not the database update.
- The batches of F1 data brought across to be validated against MPN, MCN and Register records and rejected if no match.  CSV files will need correcting and re-uploading by SCs.
- CCs will not update the F1 PPP but the DAP and RAP would be used instead.
- F1 updates could continue, but the database will not match the PPP.

## Version 1.2

### Targeted actor

Transcribers

### Features

- Load transcription CSV files into F2
- Register as a transcriber in F2
- WinREG matched to F2 (but if not, could still be used without the upload feature)
- Front-end style implementation complete across entire site
- All transcriber help and information screens complete.

### Changes required in order to effect release

 - F1 is frozen and UserID login blocked.
 - No more updates from F1 allowed.

## Version 1.3

### Targeted actor

Researchers

### Features

 - Researchers can register to access extra facilities. (What are these features?)
 - All researcher help and information screens complete.

## Future releases

- WinReg to match F2 for uploading directly.
- Emailing of CC, SC and Transcribers.
- Mail-groups.
- Add extra fields.
- Add extra for Transcribers and CC and SC.
- Add extra reports through a report generator.
- CCs and SCs can customise the DAP and RAP.
- Exception reports for CC and SC to make corrections.
- Introduce GAP report.
- Provide database statistics
- Integrate Image Server
    - All images to match Register records.
    - Transcribers to select from RAP and get permission from SC.
    - Upload images into F2.
- Researchers can leave suggested corrections.
- Researchers can subscribe to receive emails when registers change.
- On-line data entry
    - Front end processor of transcriptions, perhaps being an incorporation of WinReg.
    - Training module, with video?, needed.
- Integrate with FreeBMD an FreeCEN and others
    - Researchers can record where they have seen entries in the other projects.
    - Researchers can leave bouquets
