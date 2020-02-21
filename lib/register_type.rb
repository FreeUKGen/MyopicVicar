module RegisterType

  UNSPECIFIED = "Unspecified"

  OPTIONS = {"Parish Register" => "PR", "Transcript" => 'TR', "Archdeacon's Transcripts" => "AT", "Bishop's Transcripts" => "BT",
             "Phillimore's Transcripts" => "PH",  "Dwelly's Transcripts" => "DW", "Extract of a Register" => "EX",
             "Memorial Inscription" => "MI", "Unspecified" => " ","Phillimore's Transcript (New)" => "PT", "Dwelly's Transcript (New)" => "DT",
             "Other Transcript" => "OT", "Unknown" => "UK", "Other Document" => "OD", "Other Register" => "OR"}
  APPROVED_OPTIONS ={ "Parish Register" => "PR", "Other Transcript" => "TR", "Archdeacon's Transcript" => "AT", "Bishop's Transcript" => "BT",  "Dwelly's Transcript" => "DW","Extract of a Register" => "EX",
                      "Memorial Inscription" => "MI",  "Phillimore's Transcript" => "PH",  "Other Document" => "OD" ,"Other Register" => "OR",
                      "Unknown" => "UK","Unspecified" => " " }

  def self.display_name(value)
    APPROVED_OPTIONS.key(value)
  end

  def self.specified?(value)
    !value.blank? && !value == "Unspecified"
  end
  def self.option_values
    OPTIONS.values
  end
  def self.approved_option_values
    APPROVED_OPTIONS.values
  end
  def self.option_keys
    OPTIONS.keys
  end
  def self.approved_option_keys
    APPROVED_OPTIONS.keys
  end
end
