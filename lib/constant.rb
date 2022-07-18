module Constant
	NAME = ["First Name", "Middle Name", "Last Name", "Mothers Surname", "Other"]
	NAME_FIELD = {
		NAME[0] => "GivenName",
		NAME[1] => "OtherNames",
		NAME[2] => "Surname",
		NAME[3] => "AssociateName",
		NAME[4] => "AssociateName"
	}
	WILDCARD_OPTIONS = ["Starts with", "Contains", "Ends with"]
	FIRSTNAME_PARTIAL_OPTION = ["Contains", "Ends with", "Any"]
	MIDDLENAME_PARTIAL_OPTION = ["Starts with", "Contains", "Ends with", "Exact Match"]
	LASTNAME_PARTIAL_OPTION = ["Starts with", "Contains", "Ends with"]
	MOTHERSNAME_PARTIAL_OPTION = ["Starts with", "Contains", "Ends with"]
	OTHER_PARTIAL_OPTION = ["In First Name or Middle Name", "In Middle Name or Surname"]
	ADDITIONAL = "Exact Match"
	WILDCARD_OPTIONS_HASH = {
		"Starts with" => "starts_with",
		"Contains" => "contains",
		"Ends with" => "ends_with",
		"Any"	=> "any",
		"Exact Match" => "exact_match",
		"In First Name or Middle Name" => "first_or_middle_name",
		"In Middle Name or Surname" => "middle_or_surname"
	}

	OPTIONS_HASH = {
		NAME[0] => FIRSTNAME_PARTIAL_OPTION,
		NAME[1] => MIDDLENAME_PARTIAL_OPTION,
		NAME[2] => LASTNAME_PARTIAL_OPTION,
		NAME[3] => MOTHERSNAME_PARTIAL_OPTION,
		NAME[4] => OTHER_PARTIAL_OPTION
	}

	PRIVACY_POLICY_LINK = "https://drive.google.com/file/d/10r_c-5d9DDces-OUX7D4UJJKGNIhu8sV/view"
	EVENT_QUARTER_TO_YEAR = 589
end