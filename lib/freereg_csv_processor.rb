class FreeregCsvProcessor
#coding: utf-8

  require "csv"
  require 'email_veracity'
  require 'text'
  require "unicode"
  require 'chapman_code'
  # Reconsider this!
  require "#{Rails.root}/app/models/freereg1_csv_file"
  require "record_type"

  HEADER_FLAG = /\A\#\z/
  VALID_AGE_MAXIMUM = {'d' => 100, 'w' => 100 , 'm' => 100 , 'y' => 120}
  VALID_AGE_TYPE1 = /\A\d{1,3}\z/
  VALID_AGE_TYPE2 = /^(\d{1,2})([dwmy])/
  VALID_AGE_TYPE3 =  /^(\d{1,2})([dwmy])(\d{1,2})([dwmy])/
  VALID_AGE_TYPE4 = /\A [[:xdigit:]] \z/
  VALID_AGE_WORDS = ["infant", "child", "minor", "of age","full age","of full age"]
  VALID_CHAR = /[^a-zA-Z\d\!\+\=\_\&\?\*\)\(\]\[\}\{\'\" \.\,\;\/\:\r\n\@\$\%\^\-\#]/
  VALID_DAY = /\A\d{1,2}\z/
  VALID_MONTH = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC", "*","JANUARY","FEBRUARY","MARCH","APRIL","MAY","JUNE","JULY","AUGUST","SEPTEMBER","OCTOBER","NOVEMBER","DECEMBER"]
  VALID_YEAR = /\A\d{4,5}\z/
  VALID_MALE= ["SON"]
  VALID_FEMALE =["DAU"]
  VALID_RECORD_TYPE = ["BAPTISMS", "MARRIAGES", "BURIALS", "BA","MA", "BU"]
  RECORD_TYPE_TRANSLATION = {
    "BAPTISMS" => RecordType::BAPTISM, 
    "MARRIAGES" => RecordType::MARRIAGE, 
    "BURIALS" => RecordType::BURIAL, 
    "BA" => RecordType::BAPTISM,
    "MA" => RecordType::MARRIAGE, 
    "BU" => RecordType::BURIAL
  }
  VALID_DATE = Regexp.new('^\d{1,2}[\s-][A-Za-z]{3,3}[\s-]\d{2,4}')
  VALID_CCC_CODE = /\AC{3,5}\z/
  VALID_CREDIT_CODE = ["CREDIT", "Credit", "credit"]
  VALID_NAME = /[^A-Za-z\)\(\]\[\}\{\?\*\'\"\ \.\,\;\:\_]/
  VALID_TEXT = /[^A-Za-z\)\(\]\[\}\{\?\*\'\"\ \.\,\;\:\_\!\+\=]/
  VALID_SEX = /\A[\*\?\_\sMmFf-]{1}\z/
  VALID_REGISTER_TYPES = /\A[AaBbDdEeTtPp][TtXxRr]'?[Ss]?*$\z/
  WILD_CHARACTER = /[\*\_\?]/
  WORD_EXPANSIONS =  {
            'Saint' => 'St.',
            'St' => 'St.',
            'Gt' => 'Great',
            'Gt.' => 'Great',
            'Lt' => 'Little',
            'Lt.' => 'Little',
            '&' => "and",
            'nr' => 'near'}
  CAPITALIZATION_WORD_EXCEPTIONS = [
            "a", "an", "and", "at", "but", "by", "cum", "de", "for", "has", "in", "la", "le", "near", "next", "nor", "nr", "or", "on", "of", "so", 
            "the", "to", "von", "with", "yet"]
  VALID_MARRIAGE_CONDITIONS = {
          'Singleman' => 'Single Man',
          'Singlaman' => 'Single Man',
          'Singlewoman' => 'Single Woman',
          'Singl Woman' => 'Single Woman',
          'Single Person' => 'Single',
          'Virgine' => 'Virgin',
          'Bach' => 'Bachelor',
          'Bac' => 'Bachelor',
          'Bch' => 'Bachelor',
          'Batchelor' => 'Bachelor',
          'Batcher' => 'Bachelor',
          'Bachelore' => 'Bachelor',
          'B' => 'Bachelor',
          'Sing' => 'Single',
          'Spin' => 'Spinster',
          'Spin.' => 'Spinster',
          'Spiinster' => 'Spinster',
          'Spinister' => 'Spinster',
          'Spinspter' => 'Spinster',
          'Maiden and Spinster' => 'Spinster',
          'Maiden' => 'Spinster',
          'Single Woman and Spinster' => 'Spinster',
          'Minor and Spinster' => 'Spinster',
          'Spinster and Minor' => 'Spinster',
          'Spinster Minor' => 'Spinster',
          'Sp' => 'Spinster',
          'Spr' => 'Spinster',
          'Singl' => 'Single',
          'S' => 'Single',
          'Wid' => 'Widowed',
          'Wid.' => 'Widowed',
          'Widw' => 'Widow',
          'Widdow' => 'Widow',
          'A Widowe' => 'Widow',
          'Spinster Widow' => 'Widow',
          'Widowe' => 'Widow',
          'Wido' => 'Widow',
          'Br Widow' => 'Widow',
          'Widower [sic]' => 'Widower',
          'Widdower' => 'Widower',
          'Widwr' => 'Widower',
          'Widr' => 'Widower',
          'Wdr' => 'Widower',
          'W' => 'Widowed',
          'Relict' => 'Widow',
          'Jun' => 'Minor',
          'A Minor' => 'Minor',
          '*' => '*',
          '?' => '*',
          'Divorcee' => "Divorcee",
          'Juvenis' => 'Minor'}



  def initialize(filename,userid)
    # turn off domain checks -- some of these email accounts may no longer work and that's okay
    EmailVeracity::Config[:skip_lookup]=true

    @userid = userid
    @charset = "iso-8859-1"
    @file = File.new(filename, "r" , external_encoding:@charset , internal_encoding:"UTF-8")
    @filename = filename # BWB was filename.upcase but this breaks case-sensitive filesystems
    @csvdata = Array.new
    @datemin = 2020
    @datemax = 1530
    @datepop = Array.new(50){|i| i * 0 }

  end

  # validate the modern date of creation or modification
  def datevalmod(x)
    return true if x.nil? || x.empty?
    return true if x =~ VALID_DATE
    return false
  end

  #calculate the minimum and maximum dates in the file; also populate the decadal content table starting at 1530
  def datestat(x)
    return true if x.nil? || x.empty?
      xx = x.to_i
      @datemax = xx if xx > @datemax
      @datemin = xx if xx < @datemin
      xx = (xx-1530)/10 unless xx <= 1530 # avoid division into zero
      @datepop[xx] = @datepop[xx] + 1 unless (xx < 0 || xx > 50) #avoid going outside the data range array
  end

  #validate dates in the record and allow for the split date format 1567/8 and 1567/68 creates a base year and a split year eg /8
  def datevalsplit(x)
    @splityear = nil

    return true if x.nil? || x.empty? 
      a = x.split(" ")
      if a.length == 3
        #work with  dd mmm yyyy/y
        #firstly deal with the dd and allow the wild character
        return false unless (a[0].to_s =~ VALID_DAY || a[0].to_s =~ WILD_CHARACTER)
        #deal with the month allowing for the wild character
        return false unless VALID_MONTH.include?(Unicode::upcase(a[1]))
          #deal with the year and split year
          if a[2].length >4
            #deal with the split year
             @splityear = a[2]
              a[2]= a[2][0..-(a[2].length-3)]
              @splityear = @splityear[-(@splityear.length-4)..-1]
              datestat(a[2]) 
              return true
          else
              #deal with the yyyy and permit the wild character
              return false  unless (a[2].to_s =~ VALID_YEAR || a[2].to_s =~ WILD_CHARACTER)
              datestat(a[2]) unless  a[2].to_s =~ WILD_CHARACTER
              return true
          end
      else
        if a.length == 2
          #deal with dates that are mmm yyyy firstly the mmm then the split year
          return false unless VALID_MONTH.include?(Unicode::upcase(a[0]))
            if a[1].length >4
              @splityear = a[1]
              a[1]= a[1][0..-(a[1].length-3)]
              @splityear = @splityear[-(@splityear.length-4)..-1]
              datestat(a[1]) 
              return true
            else
              return false  unless (a[1].to_s =~ VALID_YEAR || a[1].to_s =~ WILD_CHARACTER)
              datestat(a[1]) unless  a[1].to_s =~ WILD_CHARACTER
              return true
            end
        else
          if a.length == 1
          #deal with dates that are year only
            if a[0].length >4
              @splityear = a[0]
              a[0]= a[0][0..-(a[0].length-3)]
              @splityear = @splityear[-(@splityear.length-4)..-1]
              datestat(a[0]) unless  a[0].to_s =~ WILD_CHARACTER
              return true
            else
              return false  unless (a[0].to_s =~ VALID_YEAR || a[0].to_s =~ WILD_CHARACTER)
              datestat(a[0]) unless  a[0].to_s =~ WILD_CHARACTER
              return true
            end
          end        
        end
      end
  end

  # clean up names
  def cleanname(m)
    return true if @csvdata[m].nil? || @csvdata[m].empty?
    return true if @csvdata[m] !=~ VALID_NAME
    return false
  end

  #clean up the sex field
  def cleansex(m)
    return true if @csvdata[m].nil? || @csvdata[m].empty?
    return true if @csvdata[m] =~ VALID_SEX
    @csvdata[m] = "M" if @csvdata[m].upcase == VALID_MALE
    @csvdata[m] = "F" if @csvdata[m].upcase == VALID_FEMALE
    return false
  end

  #clean up a text field eg abode and notes fields
  def cleantext(m)
    return true if @csvdata[m].nil? || @csvdata[m].empty?
      return true if @csvdata[m] !=~ VALID_TEXT
      return false
  end

  # clean u the conditions field and make changes according to the valconditions hash
  def cleancondition(m)
    return true if @csvdata[m].nil? || @csvdata[m].empty?
      @csvdata[m] = @csvdata[m].capitalize
      @csvdata[m] = VALID_MARRIAGE_CONDITIONS[@csvdata[m]] if VALID_MARRIAGE_CONDITIONS.has_key?(@csvdata[m])
      return true if VALID_MARRIAGE_CONDITIONS.has_value?(@csvdata[m])
      return false
  end

  #clean up the age field
  # check that the age is in one of several acceptable formats - infant
  # 1d (day), 2w (week), 3m (month), 2y5m (2 years, 5 months), or - for 'no age'
  # max 30d, 30w, 30m and 150y
  def cleanage(m)
    return true if @csvdata[m].nil? || @csvdata[m].empty?
      #test for valid words
      return true if VALID_AGE_WORDS.include?(Unicode::downcase(@csvdata[m]))
      #test for straight years
        if @csvdata[m] =~ VALID_AGE_TYPE1
         return true
        else
         #permit the n(dwmy)
          if @csvdata[m] =~ VALID_AGE_TYPE2
            duration = $1.to_i
            unit = $2.to_s
            return true unless duration > VALID_AGE_MAXIMUM[unit]
            return false
          else
            #permit the n(dwmy) m(dwmy)
            if @csvdata[m] =~ VALID_AGE_TYPE3
              duration1 = $1.to_i
              unit1 = $2.to_s
              duration2 = $1.to_i
              unit2 = $2.to_s
              return true unless duration1 > VALID_AGE_MAXIMUM[unit1]
              return true unless duration2 > VALID_AGE_MAXIMUM[unit2]
              return false
            else
              #permit the vulgar fractions
              return true if @csvdata[m] !=~ VALID_AGE_TYPE4
              return false
            end
          end
        end
  end

  #test for the character set
  def charvalid(m)
   return true if (m == "iso-8859-1"  || m.nil? || m.empty?)
     #Deal with the cp437 code which is not in ruby also deal with the macintosh instruction in freereg1
      m = "IBM437" if (m == "cp437")
      m = "macRoman" if (m == "macintosh")
      if Encoding.find(m)
        #if we have valid new character set; use it and change the file encoding
        @charset = Encoding.find(m)
        @file.close
        @file = File.new(@filename, "r" , external_encoding:@charset , internal_encoding:"UTF-8")
        #reposition the file
        get_line_of_data
        return true
      else
        return false
      end
  end

  def validregister(m)
    @register = nil
    @register_type = nil
    return true if m.nil? || m.empty? 
    a = m.split(" ")
    n = a.length
    a[-1] = a[-1].gsub(/\(?\)?/, '')
    register_words = a
      if a[-1] =~ VALID_REGISTER_TYPES then
       a[-1] = a[-1].gsub(/'?[Ss]?/, '') 
       @register_type = Unicode::upcase(a[-1])
       n = n - 1
      end
       i = 0
        while i < n do
          register_words[i] = WORD_EXPANSIONS[register_words[i]] if WORD_EXPANSIONS.has_key?(register_words[i])
          register_words[i] = Unicode::downcase(register_words[i]) unless i == 0
          register_words[i] = Unicode::capitalize(register_words[i]) unless CAPITALIZATION_WORD_EXCEPTIONS.include?(register_words[i])
          i = i + 1 
        end
      @register = register_words.shift(n).join(' ')
      return true
  end

  #get a line of data
  def get_line_of_data
    line = @file.gets
    raise FreeREGEnd,  "Empty file" if line.nil?
    CSV.parse(line) do |data|
      @csvdata = data
    end
    @csvdata.each_index  {|x| @csvdata[x] = @csvdata[x].gsub(/zzz/, ' ').gsub(/\s+/, ' ').strip unless @csvdata[x].nil? }
    return true
  end

  #process the header line 1
  # eg +INFO,David@davejo.eclipse.co.uk,password,SEQUENCED,BURIALS,cp850,,,,,,,
  def process_header_line_one(head)
    raise FreeREGHeaderError,  "First line of file does not start with +INFO it has #{@csvdata[0]}" unless ((@csvdata[0] == "+INFO") || (@csvdata[0] == "#NAME?"))
    # BWB: temporarily commenting out to test db interface
   address = EmailVeracity::Address.new(@csvdata[1])
   raise FreeREGHeaderError,  "Invalid email address #{@csvdata[1]} in first line of header" unless address.valid?
    head [:transcriber_email] = @csvdata[1]
    raise FreeREGHeaderError,  "Invalid file type #{@csvdata[4]} in first line of header" unless VALID_RECORD_TYPE.include?(@csvdata[4].gsub(/\s+/, ' ').strip.upcase)
    # canonicalize record type
    raw_record_type = @csvdata[4]
    scrubbed_record_type = Unicode::upcase(@csvdata[4]).gsub(/\s/, '')
    head [:record_type] =  RECORD_TYPE_TRANSLATION[scrubbed_record_type]
    raise FreeREGHeaderError, "Invalid characterset #{@csvdata[5]} in the first header line" unless charvalid(@csvdata[5])
    head [:characterset] = @csvdata[5]
  end

  #process the header line 2
  # eg #,CCCC,David Newbury,Derbyshire,dbysmalbur.CSV,02-Mar-05,,,,,,,
  def process_header_line_two(head)
     @csvdata = @csvdata.compact
     @number_of_fields = @csvdata.length
     raise FreeREGHeaderError, "The second header line is completely empty; please check the file for blank lines" if @number_of_fields == 0
    @csvdata[1] = @csvdata[1].upcase unless @csvdata[1].nil?
    case
      when (@csvdata[0] =~ HEADER_FLAG && @csvdata[1] =~ VALID_CCC_CODE)
         #deal with correctly formatted header
         process_header_line_two_block(head)
      when (@number_of_fields == 4) && (@csvdata[0].length > 1)
        #deal with #transcriber
        i = 0
        while i < 4  do
          @csvdata[5-i] = @csvdata[3-i]
          i +=1
        end
        @csvdata[2] = @csvdata[2].gsub(/#/, '')        
        process_header_line_two_block(head)
    when @number_of_fields == 7
      eric = Array.new
    #the basic EricD format
      eric[2] = @csvdata[1]
      eric[3] = @csvdata[2]
      eric[4] = @csvdata[4]
      eric[5] = @csvdata[5]
      i = 2
      while i < 6  do
        @csvdata[i] = eric[i]
        i +=1
      end
      process_header_line_two_block(head)
    when @number_of_fields == 1 && @csvdata[0] =~ HEADER_FLAG
     #empty line 
    when (@number_of_fields == 5) && (@csvdata[1].length > 1) && @csvdata[0] =~ HEADER_FLAG
      #,transciber,syndicate,file,date
      @csvdata[5] = @csvdata[4]
      @csvdata[4] = @csvdata[3]
      @csvdata[3] = @csvdata[2]
      @csvdata[2] = @csvdata[1]
      process_header_line_two_block(head)
    else
      puts "I did not know enough about your data format to extract transciber information at header line 2"
      puts @csvdata
    end
  
  end

  def process_header_line_two_block(head)
    raise FreeREGHeaderError, "The transcriber's name #{@csvdata[2]} can only contain alphabetic and space characters in the second header line" unless cleanname(2)
    head [:transcriber_name] = @csvdata[2]
    raise FreeREGHeaderError, "The syndicate can only contain alphabetic and space characters in the second header line" unless cleanname(2)
    head [:transcriber_syndicate] = @csvdata[3]
    head [:transcription_date] = @csvdata[5]
  end

  #process the header line 3
  # eg #,Credit,Libby,email address,,,,,,
  def process_header_line_threee(head)
     @csvdata = @csvdata.compact
     @number_of_fields = @csvdata.length
     raise FreeREGHeaderError, "The third header line is completely empty; please check the file for blank lines" if @number_of_fields == 0
    
    case 
      when (@csvdata[0] =~ HEADER_FLAG &&  VALID_CREDIT_CODE.include?(@csvdata[1]))
        #the normal case 
        process_header_line_three_block(head)
      when @number_of_fields == 1 && @csvdata[0] =~ HEADER_FLAG
        #no information just keep going
      
      when @number_of_fields == 2 && !VALID_CREDIT_CODE.include?(@csvdata[1])
         #eric special #,Credit name
         a = @csvdata[1].split(" ") 
         head [:credit_name] = a[1] if a.length == 1
         a = a.drop(1)
         head [:credit_name] = a.join(" ")
      when ((@number_of_fields == 5) && (@csvdata[1].nil?))
          #and extra comma
          @csvdata[2] = @csvdata[3]
          @csvdata[3] = @csvdata[4]
          process_header_line_three_block(head)
      else
         puts "I did not know enough about your data format to extract Credit Information at header line 3"
         @csvdata
    end
  
  end

  def process_header_line_three_block(head)
    raise FreeREGHeaderError, "The credit person name #{@csvdata[2]} can only contain alphabetic and space characters in the third header line" unless cleanname(2)
    head [:credit_name] = @csvdata[2]
    # # suppressing for the moment
    # address = EmailVeracity::Address.new(@csvdata[3])
    # raise FreeREGHeaderError, "Invalid email address '#{@csvdata[3]}' for the credit person in the third line of header" unless address.valid? || @csvdata[3].nil?
    head [:credit_email] = @csvdata[3]
    
  end

  #process the header line 4
  # eg #,05-Feb-2006,data taken from computer records and converted using Excel, LDS
  def process_header_line_four(head)
    @csvdata = @csvdata.compact
    @number_of_fields = @csvdata.length
     raise FreeREGHeaderError, "The forth header line is completely empty; please check the file for blank lines" if @number_of_fields == 0
      case 
        when (@number_of_fields == 4 && @csvdata[0] =~ HEADER_FLAG && datevalmod(@csvdata[1]))
         #standard format
          head [:modification_date] = @csvdata[1]
          head [:first_comments] = @csvdata[2]
          head [:second_comments] = @csvdata[3]
       when (@number_of_fields == 1 && @csvdata[0] =~ HEADER_FLAG)
          #empty line 
       when (@number_of_fields == 2 && @csvdata[0] =~ HEADER_FLAG && datevalmod(@csvdata[1]))
           #date and no notes
           head [:modification_date] = @csvdata[1]
       when @number_of_fields == 2 && @csvdata[0] =~ HEADER_FLAG
          # only a single comment
          head [:first_comments] = @csvdata[1]  
       when @number_of_fields == 2 && !(@csvdata[0] =~ HEADER_FLAG)
          #date only a single comment but no comma
          a = Array.new
          a = @csvdata[0].split("")
          if a[0] =~ HEADER_FLAG
             a = a.drop(1)
             head [:modification_date] = a.join("")
             head [:first_comments] = @csvdata[1]
          else
             puts "I did not know enough about your data format to extract notes Information at header line 4"
             puts @csvdata
          end 
       when (@number_of_fields == 3 && @csvdata[0] =~ HEADER_FLAG && datevalmod(@csvdata[1])) 
            #date and one note
           head [:modification_date] = @csvdata[1]
           head [:first_comments] = @csvdata[2]
       when (@number_of_fields == 3 && @csvdata[0] =~ HEADER_FLAG && datevalmod(@csvdata[2]))
            #one note and a date 
            head [:modification_date] = @csvdata[2]
            head [:first_comments] = @csvdata[1]
       when @number_of_fields == 3  && @csvdata[0] =~ HEADER_FLAG
          # Many comments
          @csvdata.drop(1)
          head [:first_comments] = @csvdata.join(" ")
       when (@number_of_fields == 4 && @csvdata[0] =~ HEADER_FLAG && datevalmod(@csvdata[1])) 
            #date and 3 comments
            head [:modification_date] = @csvdata[2]
            @csvdata = @csvdata.drop(1)
            head [:first_comments] = @csvdata.join(" ")
       when (@number_of_fields == 5 && @csvdata[0] =~ HEADER_FLAG && datevalmod(@csvdata[1])) 
            #,date and 3 comments
            head [:modification_date] = @csvdata[1]
            @csvdata = @csvdata.drop(2)
            head [:first_comments] = @csvdata.join(" ")
       
        else
            puts "I did not know enough about your data format to extract notes Information at header line 4"
            puts @csvdata
      end
   
  end

  #process the optional header line 5
  #eg +LDS,,,,
  def process_header_line_five(head)
    if @csvdata[0] == "+LDS"
      head[:lds] = "yes"
    else
      head [:lds]  = "no"
    end
  end
  #process the first 4 columns of the data record
  # County, Place, Church, Reg #

  def process_register_location(n,data_record)
    raise FreeREGError, "The county code #{ @csvdata[0]} in line #{n} is invalid or you have a blank record line " unless ChapmanCode::values.include?(@csvdata[0])
    data_record[:county] = @csvdata[0]
    # do we validate the Place field?
    raise FreeREGError, "Place field #{@csvdata[1]} in line #{n} contains non numeric characters" unless validregister(@csvdata[1])
    data_record[:place] = @register
    # do we validate the register field 
    raise FreeREGError, "Register field #{@csvdata[2]} in line #{n} contains non numeric characters" unless validregister(@csvdata[2])
    data_record[:register] = @register
    data_record[:register_type] = @register_type
    # need to add the transcriberID
    data_record[:line_id] = @userid + "." + File.basename(@filename.upcase) + "." + n.to_s
    data_record[:file_line_number] = n
    raise FreeREGError, "Register Entry Number #{@csvdata[3]} in line #{n} contains non numeric characters" unless cleantext(3)
    data_record[:register_entry_nuber] = @csvdata[3]

  end

  #process the baptism record columns
  def process_baptism_data_records(n,data_record,head)
    raise FreeREGError, "The date of the birth #{@csvdata[4]} is in the wrong format in line #{n}" unless datevalsplit(@csvdata[4])
    data_record[:birth_date_split] = @splityear
    data_record[:birth_date] = @csvdata[4]
    raise FreeREGError, "The date of the baptism #{@csvdata[5]} is in the wrong format in line #{n}" unless datevalsplit(@csvdata[5])
    data_record[:baptism_date_split] = @splityear
    data_record[:baptism_date] = @csvdata[5]
    raise FreeREGError, "The person's forename #{@csvdata[6]} contains invalid characters in line #{n}" unless cleanname(6)
    data_record[:person_forename] = @csvdata[6]
    raise FreeREGError, "The sex field #{@csvdata[7]} is not M F - or blank in line #{n}" unless cleansex(7)
    data_record[:person_sex] = @csvdata[7]
    raise FreeREGError, "The father's forename #{@csvdata[8]} contains invalid characters in line #{n}" unless cleanname(8)
    data_record[:father_forename] = @csvdata[8]
    raise FreeREGError, "The mother's forename #{@csvdata[9]} contains invalid characters in line #{n}" unless cleanname(9)
    data_record[:mother_forename] = @csvdata[9]
    raise FreeREGError, "The father's surname #{@csvdata[10]} contains invalid characters in line #{n}" unless cleanname(10)
    data_record[:father_surname] = Unicode::upcase(@csvdata[10]) unless @csvdata[10].nil?
    data_record[:father_surname] = @csvdata[10]  if @csvdata[10].nil?
    raise FreeREGError, "The mother's surname #{@csvdata[11]} contains invalid characters in line #{n}" unless cleanname(11)
    data_record[:mother_surname] = Unicode::upcase(@csvdata[11]) unless @csvdata[11].nil?
    data_record[:mother_surname] = @csvdata[11]  if @csvdata[11].nil?
    raise FreeREGError, "The abode #{@csvdata[12]} contains invalid characters in line #{n}" unless cleantext(12)
    data_record[:person_abode] = @csvdata[12]
    raise FreeREGError, "The father's occupation #{@csvdata[13]} contains invalid characters in line #{n}" unless cleantext(13)
    data_record[:father_occupation] = @csvdata[13]
    raise FreeREGError, "The notes #{@csvdata[14]} contains invalid characters in line #{n}" unless cleantext(14)
    data_record[:notes] = @csvdata[14]
    head[:datemax] = @datemax
    head[:datemin] = @datemin
    head[:daterange] = @datepop
    if head[:lds] == "yes" then
      data_record[:film] = @csvdata[15]
      data_record[:film_number] = @csvdata[16]
    end
  end
  #process the marriage data columns

  def process_marriage_data_records(n,data_record,head)
    raise FreeREGError, "The date of the marriage #{@csvdata[4]} is in the wrong format in line #{n}" unless datevalsplit(@csvdata[4])
    data_record[:marriage_date_split] = @splityear
    data_record[:marriage_date] = @csvdata[4]
    raise FreeREGError, "The groom's forename #{@csvdata[5]} contains invalid characters in line #{n}" unless cleanname(5)
    data_record[:groom_forename] = @csvdata[5]
    raise FreeREGError, "The groom's surname #{@csvdata[6]} contains invalid characters in line #{n}" unless cleanname(6)
    data_record[:groom_surname] = Unicode::upcase(@csvdata[6]) unless @csvdata[6].nil?
    data_record[:groom_surname] = @csvdata[6] if @csvdata[6].nil?
    raise FreeREGError, "The groom's age #{@csvdata[7]} contains invalid characters in line #{n}" unless cleanage(7)
    data_record[:groom_age] = @csvdata[7]
    raise FreeREGError, "The groom's parish #{@csvdata[8]} contains invalid characters in line #{n}" unless cleantext(8)
    data_record[:groom_parish] = @csvdata[8]
#    raise FreeREGError, "The groom's condition #{@csvdata[9]} contains unknown condition #{@csvdata[9]} in line #{n}" unless cleancondition(9)
    raise FreeREGError, "The groom's condition #{@csvdata[9]} contains unknown condition #{@csvdata[9]} in line #{n}" unless cleantext(9)
    data_record[:groom_condition] = @csvdata[9]
    raise FreeREGError, "The groom's occupation #{@csvdata[10]} contains invalid characters in line #{n}" unless cleantext(10)
    data_record[:groom_occupation] = @csvdata[10]
    raise FreeREGError, "The groom's abode #{@csvdata[11]} contains invalid characters #{@csvdata[11]}in line #{n}" unless cleantext(11)
    data_record[:groom_abode] = @csvdata[11]
    raise FreeREGError, "The bride's forename #{@csvdata[12]} contains invalid characters in line #{n}" unless cleanname(12)
    data_record[:bride_forename] = @csvdata[12]
    raise FreeREGError, "The bride's surname #{@csvdata[13]} contains invalid characters in line #{n}" unless cleanname(13)
    data_record[:bride_surname] = Unicode::upcase(@csvdata[13]) unless @csvdata[13].nil?
    data_record[:bride_surname] = @csvdata[13] if @csvdata[13].nil?
    raise FreeREGError, "The bride's age #{@csvdata[14]} contains invalid characters in line #{n}" unless cleanage(14)
    data_record[:bride_age] = @csvdata[14]
    raise FreeREGError, "The bride's parish #{@csvdata[15]} contains invalid characters in line #{n}" unless cleantext(15)
    data_record[:bride_parish] = @csvdata[15]
#    raise FreeREGError, "The bride's condition #{@csvdata[16]} contains unknown condition in line #{n}" unless cleancondition(16)
    raise FreeREGError, "The groom's condition #{@csvdata[9]} contains unknown condition #{@csvdata[9]} in line #{n}" unless cleantext(9)
    data_record[:bride_condition] = @csvdata[16]
    raise FreeREGError, "The bride's occupation #{@csvdata[17]} contains invalid characters in line #{n}" unless cleantext(17)
    data_record[:bride_occupation] = @csvdata[17]
    raise FreeREGError, "The bride's abode #{@csvdata[18]} contains invalid characters in line #{n}" unless cleantext(18)
    data_record[:bride_abode] = @csvdata[18]
    raise FreeREGError, "The groom's fathers forename #{@csvdata[19]} contains invalid characters in line #{n}" unless cleanname(19)
    data_record[:groom_father_forename] = @csvdata[19]
    raise FreeREGError, "The groom's fathers surname #{@csvdata[20]} contains invalid characters in line #{n}" unless cleanname(20)
    data_record[:groom_father_surname] = Unicode::upcase(@csvdata[20]) unless @csvdata[20].nil?
    data_record[:groom_father_surname] = @csvdata[20] if @csvdata[20].nil?
    raise FreeREGError, "The groom's father's occupation #{@csvdata[21]} contains invalid characters in line #{n}" unless cleantext(21)
    data_record[:groom_father_occupation] = @csvdata[21]
    raise FreeREGError, "The bride's fathers forename #{@csvdata[22]} contains invalid characters in line #{n}" unless cleanname(22)
    data_record[:bride_father_forename] = @csvdata[22]
    raise FreeREGError, "The bride's fathers surname #{@csvdata[23]} contains invalid characters in line #{n}" unless cleanname(23)
    data_record[:bride_father_surname] = Unicode::upcase(@csvdata[23]) unless @csvdata[23].nil?
    data_record[:bride_father_surname] = @csvdata[23] if @csvdata[23].nil?
    raise FreeREGError, "The bride's father's occupation #{@csvdata[24]} contains invalid characters in line #{n}" unless cleantext(24)
    data_record[:bride_father_occupation] = @csvdata[24]
    raise FreeREGError, "The first witness forename #{@csvdata[25]} contains invalid characters in line #{n}" unless cleanname(25)
    data_record[:witness1_forename] = @csvdata[25]
    raise FreeREGError, "The first witness's surname #{@csvdata[26]} contains invalid characters in line #{n}" unless cleanname(26)
    data_record[:witness1_surname] = Unicode::upcase(@csvdata[26]) unless @csvdata[26].nil?
    data_record[:witness1_surname] = @csvdata[26] if @csvdata[26].nil?
    raise FreeREGError, "The second witness forename #{@csvdata[27]} contains invalid characters in line #{n}" unless cleanname(27)
    data_record[:witness2_forename] = @csvdata[27]
    raise FreeREGError, "The second witness's surname #{@csvdata[28]} contains invalid characters in line #{n}" unless cleanname(28)
    data_record[:witness2_surname] = Unicode::upcase(@csvdata[28]) unless @csvdata[28].nil?
    data_record[:witness2_surname] = @csvdata[28] if @csvdata[28].nil?
    raise FreeREGError, "The notes #{@csvdata[29]} contains invalid characters in line #{n}" unless cleantext(29)
    data_record[:notes] = @csvdata[29]

    head[:datemax] = @datemax
    head[:datemin] = @datemin
    head[:daterange] = @datepop
    if head[:lds] == "yes"  then
      data_record[:film] = @csvdata[30]
      data_record[:film_number] = @csvdata[31]
    end
  end

  #process the burial data columns
  def process_burial_data_records(n,data_record,head)
    raise FreeREGError, "The date of the burial #{@csvdata[4]} is in the wrong format in line #{n}" unless datevalsplit(@csvdata[4])
    data_record[:burial_date_split] = @splityear
    data_record[:burial_date] = @csvdata[4]
    raise FreeREGError, "The person's forename #{@csvdata[5]} contains invalid characters in line #{n}" unless cleanname(5)
    data_record[:burial_person_forename] = @csvdata[5]
    raise FreeREGError, "The relationship #{@csvdata[6]} contains invalid characters in line #{n}" unless cleanname(6)
    data_record[:relationship] = @csvdata[6]
    raise FreeREGError, "The male relative's forename #{@csvdata[7]} contains invalid characters in line #{n}" unless cleanname(7)
    data_record[:male_relative_forename] = @csvdata[7]
    raise FreeREGError, "The female relative's forename #{@csvdata[8]} contains invalid characters in line #{n}" unless cleanname(8)
    data_record[:female_relative_forename] = @csvdata[8]
    raise FreeREGError, "The relative's surname #{@csvdata[9]} contains invalid characters in line #{n}" unless cleanname(9)
    data_record[:relative_surname] = Unicode::upcase(@csvdata[9]) unless @csvdata[9].nil?
    data_record[:relative_surname] = @csvdata[9] if @csvdata[9].nil?
    raise FreeREGError, "The person's surname #{@csvdata[10]} contains invalid characters in line #{n}" unless cleanname(10)
    data_record[:burial_person_surname] = Unicode::upcase(@csvdata[10])  unless @csvdata[10].nil?
    data_record[:burial_person_surname] = @csvdata[10]  if @csvdata[10].nil?
    raise FreeREGError, "The person's age #{@csvdata[11]} contains invalid characters in line #{n}" unless cleanage(11)
    data_record[:person_age] = @csvdata[11]
    raise FreeREGError, "The person's abode #{@csvdata[12]} contains invalid characters in line #{n}" unless cleantext(12)
    data_record[:burial_person_abode] = @csvdata[12]
    raise FreeREGError, "The notes #{@csvdata[13]} contains invalid characters in line #{n}" unless cleantext(13)
    data_record[:notes] = @csvdata[13]

    head[:datemax] = @datemax
    head[:datemin] = @datemin
    head[:daterange] = @datepop
    if head[:lds] == "yes"  then
      data_record[:film] = @csvdata[14]
      data_record[:film_number] = @csvdata[15]
    end
  end

  def create_db_record_for_entry(data_record)
    # TODO: bring data_record hash keys in line with those in Freereg1CsvEntry
    entry = Freereg1CsvEntry.new(data_record)
    entry.freereg1_csv_file=@freereg1_csv_file
    entry.save!
    entry
  end

  def create_or_update_db_record_for_file(head)
    if @freereg1_csv_file
        @freereg1_csv_file.update_attributes!(head)
    else
      old_freereg1_csv_file = Freereg1CsvFile.find_by_file_name_and_userid(head[:file_name], head[:userid])
      if old_freereg1_csv_file

        # this is an old record -- delete it before we create a new one
#        old_freereg1_csv_file.freereg1_csv_entries.search_record.delete_all
        old_freereg1_csv_file.freereg1_csv_entries.all.each { |e| e.search_record.destroy if e.search_record }
        old_freereg1_csv_file.freereg1_csv_entries.destroy_all
        old_freereg1_csv_file.delete
      end

      @freereg1_csv_file = Freereg1CsvFile.create!(head)
    end
    @freereg1_csv_file
  end

  def self.delete_all
    Freereg1CsvEntry.delete_all
    Freereg1CsvFile.delete_all
    SearchRecord.delete_freereg1_csv_entries
  end


  def self.process(filename)
    new_db_record = nil
    #this is the basic processing
    begin 
       
      standalone_filename = File.basename(filename)
      # get the user ID represented by the containing directory
      full_dirname = File.dirname(filename)

      parent_dirname = File.dirname(full_dirname)
      user_dirname = full_dirname.sub(parent_dirname, '').gsub(File::SEPARATOR, '')
      print "#{user_dirname}\t#{standalone_filename}\n"
      # TODO convert character sets as in freereg_csv_processor
      #need to make these passed parameters 

       file_for_warning_messages = "test_data/warning/messages.log"
       FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
       message_file = File.new(file_for_warning_messages, "a")
       user_file_for_warning_messages = full_dirname + '/' + standalone_filename + ".log"
       File.delete(user_file_for_warning_messages) if File.exists?(user_file_for_warning_messages)
#    dataout = File.new(fileout, "wb")
        header = Hash.new
        data_record = Hash.new
        header[:file_name] = standalone_filename #do not capitalize filenames
        header[:userid] = user_dirname
        me = FreeregCsvProcessor.new(filename,user_dirname)
        number_of_error_messages = 0
    #deal with the headers
        me.get_line_of_data
        me.process_header_line_one(header)
        me.get_line_of_data
        me.process_header_line_two(header)
        me.get_line_of_data
        me.process_header_line_threee(header)
        me.get_line_of_data
        me.process_header_line_four(header)
        me.get_line_of_data
        me.process_header_line_five(header)
        # persist the record for the file 
        new_db_record = me.create_or_update_db_record_for_file(header)
    #deal with the data    
        n = 0
    #deal with header 5 being optional
        type = header[:record_type]
        me.get_line_of_data  if header[:lds] == 'yes'
    #keep going until we run out of data    
        loop do
          begin
            n = n + 1
            me.process_register_location(n,data_record)
             case type
             when RecordType::BAPTISM then me.process_baptism_data_records(n,data_record,header)
             when RecordType::BURIAL then me.process_burial_data_records(n,data_record,header)                      
             when RecordType::MARRIAGE then me.process_marriage_data_records(n,data_record,header)
             end
      #store the processed data   
            me.create_db_record_for_entry(data_record)
            me.get_line_of_data
      #   break if n == 6
      #rescue the freereg data errors and continue processing the file
          rescue FreeREGError => free
            @user_message_file = File.new(user_file_for_warning_messages, "w")  if number_of_error_messages == 0
            number_of_error_messages = number_of_error_messages + 1
            puts free.message
            puts @csvdata
            message_file.puts "#{user_dirname}.#{standalone_filename}.#{n}*********************has errors*********** ***********" 
            message_file.puts "#{user_dirname}.#{standalone_filename}.#{n}" + free.message
            @user_message_file.puts free.message
            me.get_line_of_data
            retry
          end
        end
    #rescue FreeREG file header errors and stop processing the file
    rescue FreeREGHeaderError => free
      user_message_file = File.new(user_file_for_warning_messages, "w")
      number_of_error_messages = number_of_error_messages + 1
      puts free.message
      message_file.puts "#{user_dirname}.#{standalone_filename}.#{n}*********************has errors*********** ***********" 
      message_file.puts "#{user_dirname}.#{standalone_filename}.#{n}" + free.message
      user_message_file.puts free.message

    #rescue the end of file and close out the file
    rescue FreeREGEnd => free
      n = n - number_of_error_messages
      header[:records] = n
      header[:county] = data_record [:county]   
      header[:place] = data_record [:place]
      header[:register] = data_record [:register]
      header[:register_type] = data_record[:register_type]

      puts " Processed #{n} lines with #{number_of_error_messages} errors" 
    # print the header and add it to the processed records
    #  puts header
    #  dataout.puts header
    #  dataout.close
    me.create_or_update_db_record_for_file(header)
    rescue Exception => e 
      puts e.message
      puts e.backtrace
      message_file.puts "*********************** #{n} ***********#{standalone_filename} **************#{user_dirname}       "  
      message_file.puts e.message  
      message_file.puts e.backtrace.inspect  
    end 

    # return the record that was created
    new_db_record
  end


end
#set the FreeREG error conditions
class FreeREGError < StandardError
end

class FreeREGEnd < StandardError
end

class FreeREGHeaderError < StandardError
end
# 
# require 'pry'


