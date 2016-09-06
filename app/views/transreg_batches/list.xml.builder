xml.BatchesTable do
  if @batches.present?
	@batches.each do |batch|
	 	xml.Batch do
	 		xml.ID batch._id
			xml.CountyName batch.county
			xml.PlaceName batch.place
			xml.ChurchName batch.church_name
			xml.RegisterType batch.register_type
			xml.RecordType batch.record_type
			xml.Records batch.records
			xml.DateMin batch.datemin
			xml.DateMax batch.datemax
			xml.DateRange batch.daterange
			xml.UserId batch.userid
			xml.UserIdLowerCase batch.userid_lower_case
			xml.FileName batch.file_name
			xml.TranscriberName batch.transcriber_name
			xml.TranscriberEmail batch.transcriber_email
			xml.TranscriberSyndicate batch.transcriber_syndicate
			xml.CreditEmail batch.credit_email
			xml.CreditName batch.credit_name
			xml.FirstComment batch.first_comment
			xml.SecondComment batch.second_comment
			xml.TranscriptionDate batch.transcription_date
			xml.ModificationDate batch.modification_date
			xml.UploadedDate batch.uploaded_date
			xml.Error batch.error
			xml.Digest batch.digest
			xml.LockedByTranscriber batch.locked_by_transcriber
			xml.LockedByCoordinator batch.locked_by_coordinator
			xml.lds batch.lds
			xml.Action batch.action
			xml.CharacterSet batch.characterset
			xml.AlternateRegisterName batch.alternate_register_name
			xml.CsvFile batch.csvfile
		end
	end
  end
end
