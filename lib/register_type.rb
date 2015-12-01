module RegisterType

UNSPECIFIED = "Unspecified"

OPTIONS = {"Parish Register" => "PR", "Transcript" => 'TR', "Archdeacon's Transcripts" => "AT", "Bishop's Transcripts" => "BT",  
	"Phillimore's Transcripts" => "PH",  "Dwelly's Transcripts" => "DW", "Extract of a Register" => "EX", 
	"Memorial Inscription" => "MI", UNSPECIFIED => " "}

  def self.display_name(value)
    # binding.pry
    OPTIONS.key(value)
  end	
  
  def self.specified?(value) 
    !value.blank? && !value == UNSPECIFIED
  end

end