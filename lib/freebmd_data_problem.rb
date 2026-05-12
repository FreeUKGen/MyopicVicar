require_relative 'gro_abbrev' unless defined?(GroAbbrev::ACCESSIBILITY_HTML)

module FreebmdDataProblem
	# Alias for convenience in interpolated strings (canonical value: GroAbbrev::ACCESSIBILITY_HTML).
	GRO_ABBREV_ACCESSIBILITY_HTML = GroAbbrev::ACCESSIBILITY_HTML

	QUESTIONS = [
		"An error",
		"Data is missing",
		"Anything else/miscellaneous"
	]
	# Report error page: 3 main sections, each with subsections (accordion). Id is stored as contact.query.
	# Each subsection :answer may be plain text (wrapped in <p> by the view) or HTML (e.g. multiple <p>, <ul>, <a>).
	# Use HTML when you need paragraphs, lists or links; content is sanitized before output.
	# Optional :form_numbers controls which UI blocks appear in report_error (toggle logic in contacts/report_error.html.erb JS):
	#   1 => contacts/report_error/_form_block_main_contact.html.erb + shared hidden fields partial
	#   2 => contacts/report_error/_form_block_corrections_table.html.erb
	#   3 => contacts/report_error/_form_block_missing_entry_details.html.erb
	#   4 => no separate partial; tweaks #contact_report_body label/placeholder/required via JS only
	# Example: form_numbers: [1,2] shows main contact fields and corrections table.
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
						<p>If you believe there is an error in the #{GRO_ABBREV_ACCESSIBILITY_HTML} Index, you will need to <a href="https://www.gro.gov.uk/gro/content/certificates/contact_us.asp" target="_blank" rel="noopener">contact them</a> to request a correction.</p>
						<p>If the #{GRO_ABBREV_ACCESSIBILITY_HTML} confirms the correction, please let us know and we will add a note to the relevant entry on FreeBMD.</p>
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
								<p>Use a wildcard search to find surrounding entries. See <a href="/help/search_help#firstname_surname" target="_blank" rel="noopener">Search help: First name &amp; Surname</a>.</p>
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
							    <p>If you have identified that an entry on a transcribed page has not been transcribed you should report the missing entry/entries via the immediately preceding entry (use a <a href="/help/search_help#firstname_surname" target="_blank" rel="noopener">wildcard search</a> to get surrounding entries) filling in the details of the missing entry (only those fields that are different from the preceding entry need be completed). The <strong>Missing entry or entries</strong> box must be checked. If there are multiple missing entries, fill in the details for the first and check the <strong>Multiple entries</strong> box in addition to the <strong>Missing entry or entries</strong> box</p>
							HTML
							show_form: false
						}
					]
				},
				{
					id: 3, label: "A record is missing from the GRO index scan",
					answer: <<~HTML.strip,
						<p>We cannot do anything about data missing from the #{GRO_ABBREV_ACCESSIBILITY_HTML}. If you believe that a record is missing from the #{GRO_ABBREV_ACCESSIBILITY_HTML} index you will need to <a href="https://www.gro.gov.uk/gro/content/certificates/contact_us.asp" target="_blank" rel="noopener">contact them</a> to discuss.</p>
						<p>If you receive resolution from the #{GRO_ABBREV_ACCESSIBILITY_HTML}, please share this information with us.</p>
					HTML
					show_form: false
				}
			]
		},
		{
			title: "Anything else/miscellaneous",
			subsections: [
				{ id: 4, label: "E.g. scan image not clear, or a particular Year/Quarter/Event has a page missing etc.",
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