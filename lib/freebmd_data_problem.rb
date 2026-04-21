require_relative 'gro_abbrev' unless defined?(GroAbbrev::ACCESSIBILITY_HTML)

module FreebmdDataProblem
	# Alias for convenience in interpolated strings (canonical value: GroAbbrev::ACCESSIBILITY_HTML).
	GRO_ABBREV_ACCESSIBILITY_HTML = GroAbbrev::ACCESSIBILITY_HTML

	QUESTIONS = [
		"An error",
		"Data is missing",
		"Anything else/miscellaneous"
	]

	ANSWERS = [
		"FreeBMD transcribes exactly what is in the #{GRO_ABBREV_ACCESSIBILITY_HTML} index, and we do not change it to be correct as per the #{GRO_ABBREV_ACCESSIBILITY_HTML} certificate, or other certain knowledge. You may use the postem system (linked) to provide this information, which may be of great help to other family historians. If you wish to get the #{GRO_ABBREV_ACCESSIBILITY_HTML} Index corrected you should apply to the #{GRO_ABBREV_ACCESSIBILITY_HTML} [please put information here from https://www.freebmd.org.uk/FAQ.html#22].",
		"FreeBMD transcribes EXACTLY what is in the #{GRO_ABBREV_ACCESSIBILITY_HTML} index for this event, and we do not change it to be correct as per another event in the index. If you wish to get the #{GRO_ABBREV_ACCESSIBILITY_HTML} Index corrected you should apply to the #{GRO_ABBREV_ACCESSIBILITY_HTML} [please link here to information on FreeBMD2 from https://www.freebmd.org.uk/FAQ.html#22].",
		"If you have identified that an entry or entries on a scan of a page has not been transcribed you should attach a correction to the immediately preceding entry (find the name on the page and search using those details, and use the 'report a data error' button on that record.
If you have done this, and are back at this point, please use this link [link to reporting page] to report the following entry as missing.  You only need to change the details that are different, such as the name of the missing person, and check the 'missing entry' or 'missing entries' box - you only need to check the missing entries box on the first person if multiple entries are missing: we will make sure all the missing entries are transcribed."
	]

	QUESTIONS2 = [
		"The entry does not match what I know, from the GRO certificate, a census, church register, family bible or similar source",
		"There are two entries, with slightly different spellings, I know which is correct",
		"There is an error in the spelling of the District name",
		"The District is not the place where the person was born, married, or died",
		"The month recorded is wrong: I know the precise date of the event",
		"The quarter recorded is wrong: I know the precise date of the event",
		"I want to report that the spouse is missing from the results",
		"I want to report that the entry is missing from a scan",
		"I want to report a missing entry (and I can see it on a scan)",
		"I want to report a missing entry (I have not seen it on a scan)",
		"There are two nearly-identical entries for the same event",
		"There are two entries which appear to be identical",
		"There are characters such as square brackets, curly brackets underlines or asterisks in the entry",
		"The entry for this event (e.g.  age at death) does not match what I know, from another FreeBMD event for this person (e.g.their birth registration)",
		"The entry for this event (e.g. bride's surname at marriage) does not match the FreeBMD entry for another person at this event (e.g. spelling of her name in spouse's).",
		"I have checked the scan and the transcription does not match what has been transcribed"
	]

	ANSWERS2 = [
		"FreeBMD transcribes exactly what is in the #{GRO_ABBREV_ACCESSIBILITY_HTML} index, and we do not change it to be correct as per the #{GRO_ABBREV_ACCESSIBILITY_HTML} certificate, or other certain knowledge. You may use the postem system (linked) to provide this information, which may be of great help to other family historians. If you wish to get the #{GRO_ABBREV_ACCESSIBILITY_HTML} Index corrected you should apply to the #{GRO_ABBREV_ACCESSIBILITY_HTML} [please put information here from https://www.freebmd.org.uk/FAQ.html#22].",
		"It is not an error to find names appearing twice under alternative spellings in the Index. This happened when names were poorly written on the original copy. You may use the postem system (linked) to provide this information, which may be of help to other family historians.",
		"Districts are spelt and abbreviated in a variety of ways. FreeBMD records the actual spelling from the index and links this to the definitive form of the name for searching, so we do not 'correct' them. To see the definitive form, you can click on the name of the district.",
		"The Registration District covers a larger area than the location with the same name as the Registration District, and some places were covered by more than one registration district (at the same time) or moved between registration districts over time. We know it can be confusing to see an unexpected place name, and therefore have put a link from the district name to a page which gives a detailed and comprehensive history of that registration district.",
		"This can happen for two reasons. One is that before 1984 events were recorded in quarters rather than months, so events in, for example, January, February and March are correctly recorded as being in the March quarter. Also, events which took place late in a quarter might not be registered until early in the following quarter.",
		"Events are recorded in the quarter that they were registered, not the quarter when they occurred. It is perfectly possible that a birth in May will appear in the September Quarter, because it was not registered until July..",
		"Please do not use this form to report that the spouse is missing from a spouse search - see here for help on finding a missing spouse. Bear in mind that FreeBMD is a work in progress and the spouse record may be on a page that has not yet been transcribed. Once you have found a missing spouse you can, of course, submit a correction if that entry is in error or missing from a transcribed page.",
		"To report a problem with a scan, please start on the Entry Page with the issue.  [see also https://docs.google.com/document/d/17EzCa8Gl130ACmG00LEJFKcAU-83Yg2Z8Oiu0Cu0BeU/edit?usp=sharing for text which may be needed].",
		"If you have identified that an entry or entries on a scan of a page has not been transcribed you should attach a correction to the immediately preceding entry (find the name on the page and search using those details, and use the 'report a data error' button on that record.  
If you have done this, and are back at this point, please use this link [link to reporting page] to report the following entry as missing.  You only need to change the details that are different, such as the name of the missing person, and check the 'missing entry' or 'missing entries' box - you only need to check the missing entries box on the first person if multiple entries are missing: we will make sure all the missing entries are transcribed.",
"We transcribe exactly as on the #{GRO_ABBREV_ACCESSIBILITY_HTML} index, which may itself contain errors.  
If it is possible to search for this entry on the #{GRO_ABBREV_ACCESSIBILITY_HTML} website (https://www.gro.gov.uk/gro/content/certificates/login.asp - you do not need to actually order a certificate), please do so, and if it is there, let us know the volume and page concerned below/on this form.
If the entry has not yet been indexed by the #{GRO_ABBREV_ACCESSIBILITY_HTML}, please use the form below/on this form - please provide as much information as you know about the date and location of the event",
"In some circumstances there are both handwritten and typed scans available and the FreeBMD policy is that the two should be seen as completely independent attestations to the same historical event and the two should be kept and served as separate records. When submitting a correction you should check the scan(s) referenced when you click on the Scan available icon.",
"This is usually because the #{GRO_ABBREV_ACCESSIBILITY_HTML} index itself contains identical entries, and we transcribe exactly what is in the index.  Please check the scan(s) to see if this is the case.
It is also possible that this is a transcription error - if this is the case, please let us know by using the form below [form or email address?]",
	"Where the transcriber was unable to read the record fully, uncertainty will be shown by use of special characters: []{}_*. The majority of such entries will be corrected in the fullness of time as better quality source becomes available. It should be noted that as all corrections are verified before being applied, it is unlikely that our source will be any more readable now than it was when it was transcribed, and such corrections are unlikely to be applied. If you have a legible copy of this page (e.g. one you photographed when the indexes were open for public consulation), please use [this form] to provide your contact details so that we can invite you to send us the image.",
	"FreeBMD transcribes EXACTLY what is in the #{GRO_ABBREV_ACCESSIBILITY_HTML} index for this event, and we do not change it to be correct as per another event in the index. If you wish to get the #{GRO_ABBREV_ACCESSIBILITY_HTML} Index corrected you should apply to the #{GRO_ABBREV_ACCESSIBILITY_HTML} [please link here to information on FreeBMD2 from https://www.freebmd.org.uk/FAQ.html#22].",
	"FreeBMD transcribes EXACTLY what is in the #{GRO_ABBREV_ACCESSIBILITY_HTML} index for THIS  person in the event, and we do not change it to be correct as per the index for a spouse or mother. If you wish to get the #{GRO_ABBREV_ACCESSIBILITY_HTML} Index corrected you should apply to the #{GRO_ABBREV_ACCESSIBILITY_HTML} [please link to information on FreeBMD2 from https://www.freebmd.org.uk/FAQ.html#22].",
	"--",
	]

	ANSWERS3 = [
		"If our transcription does not match the information shown in the #{GRO_ABBREV_ACCESSIBILITY_HTML} index scan, please let us know using the form below. We will review the details and correct the database if needed.",
		"--",
		"--",
		"--",
		"--",
		"--",
		"--",
	]

	QUESTION_ANSWER = {
		QUESTIONS[0] => ANSWERS[0],
		QUESTIONS[1] => ANSWERS[1],
		QUESTIONS[2] => ANSWERS[2]
	}

		SECOND_QUESTION_ANSWER = {
		QUESTIONS2[0] => ANSWERS2[0],
		QUESTIONS2[1] => ANSWERS2[1],
		QUESTIONS2[2] => ANSWERS2[2],
		QUESTIONS2[3] => ANSWERS2[3],
		QUESTIONS2[4] => ANSWERS2[4],
		QUESTIONS2[5] => ANSWERS2[5],
		QUESTIONS2[6] => ANSWERS2[6],
		QUESTIONS2[7] => ANSWERS2[7],
		QUESTIONS2[8] => ANSWERS2[8],
		QUESTIONS2[9] => ANSWERS2[9],
		QUESTIONS2[10] => ANSWERS2[10],
		QUESTIONS2[11] => ANSWERS2[11],
		QUESTIONS2[12] => ANSWERS2[12],
		QUESTIONS2[13] => ANSWERS2[13],
		QUESTIONS2[14] => ANSWERS2[14],
		QUESTIONS2[15] => ANSWERS2[15]
	}

	QUESTION_VALUE = QUESTIONS.map{|v| %W(#{v} #{QUESTIONS.index(v)})}

	SECOND_QUESTION_VALUE = QUESTIONS2.map{|v| %W(#{v} #{QUESTIONS2.index(v)})}

	# Report error page: 3 main sections, each with subsections (accordion). Id is stored as contact.query.
	# Each subsection :answer may be plain text (wrapped in <p> by the view) or HTML (e.g. multiple <p>, <ul>, <a>).
	# Use HTML when you need paragraphs, lists or links; content is sanitized before output.
	# In :answer / ANSWERS* strings, interpolate +GRO_ABBREV_ACCESSIBILITY_HTML+ (same string as GroAbbrev::ACCESSIBILITY_HTML).
	# Plain "GRO" in :label and QUESTIONS2 is still expanded in the report_error view via +gro_abbrev_in_user_text+.
	# Optional :form_numbers controls which UI blocks appear in report_error:
	#   1 => main report form
	#   2 => corrections table block
	# Example: form_numbers: [1,2] shows both.
	# A subsection hash may use :children => [ {...}, ... ] instead of :id/:answer at the top level;
	# those appear as a nested accordion under :label (shared heading).
	REPORT_ERROR_SECTIONS = [
		{
			title: "An error",
			subsections: [
				{
					id: 0,
					label: "The transcription information does not match the scan.",
					answer: <<~HTML.strip,
						<p>If our transcription does not match the information shown in the #{GRO_ABBREV_ACCESSIBILITY_HTML} index scan, please let us know using the form below. We will review the details and correct the database if needed.</p>
						<p>Enter the correct information in the relevant field(s) on the form below. Please read our <a href="{{PRIVACY_POLICY_LINK}}">Privacy Notice</a> for information on how we will protect and use your data, and then complete the form below.</p>
					HTML
					show_form: true,
					form_numbers: [1,2]
				},
				{ id: 1,
				  label: "The transcription information does match the GRO index scan.",
				  answer: <<~HTML.strip,
						<p>We cannot change the database if our transcription matches the information on the #{GRO_ABBREV_ACCESSIBILITY_HTML} index (scan).</p>
						<p>If you believe there is an error in the #{GRO_ABBREV_ACCESSIBILITY_HTML} Index, you will need to contact the <a href="https://www.gro.gov.uk/" target="_blank" rel="noopener">General Register Office (#{GRO_ABBREV_ACCESSIBILITY_HTML})</a> to request a correction.</p>
						<p>If the #{GRO_ABBREV_ACCESSIBILITY_HTML} confirms the correction, please let us know and we will add a note to the relevant entry on FreeBMD.</p>
						<small>(Was: If you wish to get the #{GRO_ABBREV_ACCESSIBILITY_HTML} Index corrected you should apply to the #{GRO_ABBREV_ACCESSIBILITY_HTML}. Contact the #{GRO_ABBREV_ACCESSIBILITY_HTML} with the appropriate information. When they agree to the correction let us know and we will annotate FreeBMD appropriately.)</small>
					HTML
				  show_form: false }
			]
		},
		{
			title: "Data is missing",
			subsections: [
				{
					label: "A record appears on the GRO index scan but is missing from our database OR we have only transcribed part of the page",
					children: [
						{
							id: 2,
							label: "You have the scan",
							answer: <<~HTML.strip,
								<p>If you have identified that an entry on a transcribed page has not been transcribed, please attach a correction to the immediately preceding entry.</p>
								<p>Use a wildcard search to find surrounding entries. See <a href="https://www.freebmd2.org.uk/help/search_help#first-name-surname" target="_blank" rel="noopener">Search help: First name &amp; Surname</a>.</p>
								<p>When reporting, fill in details of the missing entry. You only need to complete fields that are different from the preceding entry. The <strong>Missing entry or entries</strong> box must be checked.</p>
								<p>If there are multiple missing entries, enter details for the first missing entry and also check the <strong>Multiple entries</strong> box.</p>
								<p>Please read our <a href="{{PRIVACY_POLICY_LINK}}">Privacy Notice</a> for information on how we protect and use your data, then complete the form below.</p>
							HTML
							show_form: true,
							form_numbers: [1, 3]
						},
						{
							id: 6,
							label: "You do not have the scan",
							answer: <<~HTML.strip,
							    <p>Advice on how to find the scan - preceding entry. See <a href="/help/search_help#firstname_surname">Search help: First name &amp; Surname</a></p>
								<p>If you have identified that an entry on a transcribed page has not been transcribed you should attach a correction to the immediately preceding entry (use a wildcard search to get surrounding entries) filling in the details of the missing entry (only those fields that are different from the preceding entry need be completed). The Missing entry or entries box must be checked. If there are multiple missing entries fill in the details for the first and check the Multiple entries box in addition to the Missing entry or entries box</p>
							HTML
							show_form: false
						}
					]
				},
				{
					id: 3, label: "A record is missing from the GRO index scan",
					answer: <<~HTML.strip,
						<p>We cannot change the database if our transcription matches the information on the #{GRO_ABBREV_ACCESSIBILITY_HTML} index (scan).</p>
						<p>If you believe there is an error in the #{GRO_ABBREV_ACCESSIBILITY_HTML} Index, you will need to contact the General Register Office (#{GRO_ABBREV_ACCESSIBILITY_HTML}) to request a correction</p>
						<p>If the #{GRO_ABBREV_ACCESSIBILITY_HTML} confirms the correction, please let us know and we will add a note to the relevant entry on FreeBMD.</p>
						<small>(Was: If you wish to get the #{GRO_ABBREV_ACCESSIBILITY_HTML} Index corrected you should apply to the #{GRO_ABBREV_ACCESSIBILITY_HTML}. Contact the #{GRO_ABBREV_ACCESSIBILITY_HTML} with the appropriate information. When they agree to the correction let us know and we will annotate FreeBMD appropriately.)</small>
					HTML
					show_form: false
				}
			]
		},
		{
			title: "Anything else/miscellaneous",
			subsections: [
				{ id: 4, label: "Scan image not clear, a particular year/Qtr/event has a page missing etc",
				  answer: "Please describe the issue below and we will do our best to address it.",
				  show_form: true,
				  form_numbers: [4]
				}
			]
		}
	].freeze

	def self.subsection_by_id(id)
		REPORT_ERROR_SECTIONS.each do |section|
			section[:subsections].each do |s|
				if s[:children].present?
					found = s[:children].find { |c| c[:id].to_s == id.to_s }
					return found if found
				elsif s[:id].to_s == id.to_s
					return s
				end
			end
		end
		nil
	end
end