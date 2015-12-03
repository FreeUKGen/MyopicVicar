module RegisterType

UNSPECIFIED = "Unspecified"

OPTIONS = {"Parish Register" => "PR", "Transcript" => 'TR', "Archdeacon's Transcripts" => "AT", "Bishop's Transcripts" => "BT",  
	"Phillimore's Transcripts (Original)" => "PH",  "Dwelly's Transcripts (Original)" => "DW", "Extract of a Register" => "EX", 
	"Memorial Inscription" => "MI", "Unspecified" => " ","Phillimore's Transcript" => "PT", "Dwelly's Transcript" => "DT",
   "Other Transcript" => "OT", "Unknown" => "UK", "Other Register" => "OR"}
APPROVED_OPTIONS ={ "Archdeacon's Transcripts" => "AT", "Bishop's Transcripts" => "BT",  "Dwelly's Transcript" => "DT","Extract of a Register" => "EX", 
  "Memorial Inscription" => "MI", "Parish Register" => "PR", "Phillimore's Transcript" => "PT", "Transcript" => "TR" ,"Other Register" => "OR",
   "Unknown" => "UK"}

  def self.display_name(value)
    # binding.pry
    OPTIONS.key(value)
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