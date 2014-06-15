module RegisterType

OPTIONS = {"Parish Register" => "PR", "Transcript" => 'TR', "Archdeacon's Transcripts" => "AT", "Bishop's Transcripts" => "BT",  
	"Phillimore's Transcripts" => "PH",  "Dwellies Transcripts" => "DW", "Extract of a Register" => "EX", 
	"Memorial Inscription" => "MI", "Unspecified" => " "}

def self.display_name(value)
    # binding.pry
    OPTIONS.key(value)
  end	

end