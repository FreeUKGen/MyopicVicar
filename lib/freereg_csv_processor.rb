class FreeregCsvProcessor
#coding: utf-8

  require "csv"
  require 'email_veracity'
  require 'text'
  require "unicode"
  require 'chapman_code'
  require "#{Rails.root}/app/models/freereg1_csv_file"

  
  VALID_AGE_MAXIMUM = {'d' => 60, 'w' => 60 , 'm' => 60 , 'y' => 150}
  VALID_AGE_TYPE1 = /\A\d{1,3}\z/
  VALID_AGE_TYPE2 = /^(\d{1,2})([dwmy])/
  VALID_AGE_TYPE3 =  /^(\d{1,2})([dwmy])(\d{1,2})([dwmy])/
  VALID_AGE_TYPE4 = /\A [[:xdigit:]] \z/
  VALID_AGE_WORDS = ["infant", "child", "minor", "of age","full age","of full age"]
  VALID_CHAR = /[^a-zA-Z\d\!\+\=\_\&\?\*\)\(\]\[\}\{\'\" \.\,\;\/\:\r\n\@\$\%\^\-\#]/
  VALID_DAY = /\A\d{1,2}\z/
  VALID_MONTH = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC", "*"]
  VALID_YEAR = /\A\d{4,5}\z/
  VALID_RECORD_TYPE = ["BAPTISMS", "MARRIAGES", "BURIALS", "BA","MA", "BU"]
  RECORD_TYPE_TRANSLATION = {
    "BAPTISMS" => Freereg1CsvFile::RECORD_TYPES::BAPTISM, 
    "MARRIAGES" => Freereg1CsvFile::RECORD_TYPES::MARRIAGE, 
    "BURIALS" => Freereg1CsvFile::RECORD_TYPES::BURIAL, 
    "BA" => Freereg1CsvFile::RECORD_TYPES::BAPTISM,
    "MA" => Freereg1CsvFile::RECORD_TYPES::MARRIAGE, 
    "BU" => Freereg1CsvFile::RECORD_TYPES::BURIAL
  }
  VALID_DATE = Regexp.new('^\d{1,2}[\s-][A-Za-z]{3,3}[\s-]\d{2,4}')
  VALID_CCC_CODE = /\AC{3,5}\z/
  VALID_NAME = /[^A-Za-z\)\(\]\[\}\{\?\*\'\"\ \.\,\;\:\_]/
  VALID_TEXT = /[^A-Za-z\)\(\]\[\}\{\?\*\'\"\ \.\,\;\:\_\!\+\=]/
  VALID_SEX = /\A[\sMmFf-]{1}\z/
  VALID_REGISTER_TYPES = /\A[AaBbEeTtPp][TtXxRr]'?[Ss]?*$\z/
  WILD_CHARACTER = /[\*\_]/
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
          'Spiinster' => 'Spinster',
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




  def self.prove_you_exist
    print "I exist\n"
  end

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
    return true if x.nil?
    return true if x =~ VALID_DATE
    return false
  end

  #calculate the minimum and maximum dates in the file; also populate the decadal content table starting at 1530
  def datestat(x)
    return true if x.nil?
      xx = x.to_i
      @datemax = xx if xx > @datemax
      @datemin = xx if xx < @datemin
      xx = (xx-1530)/10 unless xx <= 1530 # avoid division into zero
      @datepop[xx] = @datepop[xx] + 1 unless (xx < 0 || xx > 50) #avoid going outside the data range array
  end

  #validate dates in the record and allow for the spli date format 1567/8 and 1567/68 creates a base year and a split year eg /8
  def datevalsplit(x)
    @splityear = nil

    return true if x.nil?
    return true if x =~ /\A\s\z/
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
    return true if @csvdata[m].nil?
      @csvdata[m] = @csvdata[m].gsub(/\s+/, ' ').strip
      return true if @csvdata[m] !=~ VALID_NAME
      return false
  end

  #clean up the sex field
  def cleansex(m)
    return true if @csvdata[m].nil?
      @csvdata[m] = @csvdata[m].gsub(/\s+/, ' ').strip
      return true if @csvdata[m] =~ VALID_SEX
      return false
  end

  #clean up a text field eg abode and notes fields
  def cleantext(m)
    return true if @csvdata[m].nil?
      @csvdata[m] = @csvdata[m].gsub(/\s+/, ' ').strip
      return true if @csvdata[m] !=~ VALID_TEXT
      return false
  end

  # clean u the conditions field and make changes according to the valconditions hash
  def cleancondition(m)
    return true if @csvdata[m].nil? || @csvdata[m].to_s =~ /\s/
      @csvdata[m] = @csvdata[m].gsub(/\s+/, ' ').strip.capitalize
      @csvdata[m] = VALID_MARRIAGE_CONDITIONS[@csvdata[m]] if VALID_MARRIAGE_CONDITIONS.has_key?(@csvdata[m])
      return true if VALID_MARRIAGE_CONDITIONS.has_value?(@csvdata[m])
      return false
  end

  #clean up the age field
  # check that the age is in one of several acceptable formats - infant
  # 1d (day), 2w (week), 3m (month), 2y5m (2 years, 5 months), or - for 'no age'
  # max 30d, 30w, 30m and 150y
  def cleanage(m)
    return true if @csvdata[m].nil?
      @csvdata[m] = @csvdata[m].gsub(/\s+/, ' ').strip
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

  #calculate the soundex using Z000 for nil
  def addsoundex(m)

    @csvdata[m] = Text::Soundex.soundex(@csvdata[m])
    @csvdata[m] = 'Z000' if (@csvdata[m].nil? ||  Text::Soundex.soundex(@csvdata[m]).nil?)
  end

  #test for the character set
  def charvalid(m)
   return true if (m == "iso-8859-1"  || m.nil? )
     #Deal with the cp437 code which is not in ruby also deal with the macintosh instruction in freereg1
      mm = m.strip
      mm = "IBM437" if (mm == "cp437")
      mm = "macRoman" if (mm == "macintosh")
      if Encoding.find(mm)
        #if we have valid new character set; use it and change the file encoding
        @charset = Encoding.find(mm)
        @file.close
        @file = File.new(@filename, "r" , external_encoding:@charset , internal_encoding:"UTF-8")
        #reposition the file
        getvalidline
        return true
      else
        return false
      end
  end

  def validregister(m)
    return true if m.nil? 
    m = m.gsub(/\s+/, ' ').strip
    a = m.split(" ")
    n = a.length
    a[-1] = a[-1].gsub(/\(?\)?/, '')
    register_words = a
    @register_type = nil
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
  def getvalidline
    line = @file.gets
    raise FreeREGEnd,  "Empty file" if line.nil?
    CSV.parse(line) do |data|
      @csvdata = data
    end
    return true
  end

  #process the header line 1
  # eg +INFO,David@davejo.eclipse.co.uk,password,SEQUENCED,BURIALS,cp850,,,,,,,
  def headerone(head)
    raise FreeREGError,  "First line of file does not start with +INFO it has #{@csvdata[0]}" unless (@csvdata[0] == "+INFO")
    # BWB: temporarily commenting out to test db interface
   address = EmailVeracity::Address.new(@csvdata[1])
   raise FreeREGError,  "Invalid email address #{@csvdata[1]} in first line of header" unless address.valid?
    head [:transcriber_email] = @csvdata[1]
    raise FreeREGError,  "Invalid file type #{@csvdata[4]} in first line of header" unless VALID_RECORD_TYPE.include?(@csvdata[4].gsub(/\s+/, ' ').strip.upcase)
    # canonicalize record type
    raw_record_type = @csvdata[4]
    scrubbed_record_type = Unicode::upcase(@csvdata[4]).gsub(/\s/, '')
    head [:record_type] =  RECORD_TYPE_TRANSLATION[scrubbed_record_type]
    raise FreeREGError, "Invalid characterset #{@csvdata[5]} in the first header line" unless charvalid(@csvdata[5])
    head [:characterset] = @csvdata[5]
  end

  #process the header line 2
  # eg #,CCCC,David Newbury,Derbyshire,dbysmalbur.CSV,02-Mar-05,,,,,,,
  def headertwo (head)
    raise FreeREGError,  "Second line of file does not start with #,CCC it has #{@csvdata[0]},#{@csvdata[1]}" unless (@csvdata[0] == "#" && (@csvdata[1] =~ VALID_CCC_CODE))
    raise FreeREGError, "The transcriber's name may not be blank in the second header line it contains #{@csvdata[2]}" if @csvdata[2].nil?
    raise FreeREGError, "The transcriber's name #{@csvdata[2]} can only contain alphabetic and space characters in the second header line" unless cleanname(2)
    head [:transcriber_name] = @csvdata[2]
    raise FreeREGError, "The syndicate name #{@csvdata[3]} may not be blank in the second header line" if @csvdata[3].nil?
    raise FreeREGError, "The syndicate can only contain alphabetic and space characters in the second header line" unless cleanname(2)
    head [:transcriber_syndicate] = @csvdata[3]
    raise FreeREGError, "The file name cannot be blank in the second header line" if @csvdata[4].nil?
    raise FreeREGError, "The internal #{@csvdata[4]} and external file #{@filename} names must match" unless Unicode::upcase(@csvdata[4]) == File.basename(@filename.upcase)
    aa = @csvdata[4].split(//).first(3).join.upcase
    raise FreeREGError, "The county code #{@csvdata[4]} in the file name is invalid #{aa}" unless ChapmanCode::values.include?(aa)
    aa = @csvdata[4].split(//)
    aaa = aa[6].to_s + aa[7].to_s
    raise FreeREGError, "The record type in the file name #{@csvdata[4]} is not one of BA, BU or MA" unless VALID_RECORD_TYPE.include?(Unicode::upcase(aaa))
    raise FreeREGError, "The date of the transcription #{@csvdata[5]} is in the wrong format" unless datevalmod(@csvdata[5])
    head [:transcription_date] = @csvdata[5]
  end

  #process the header line 3
  # eg #,Credit,Libby,email address,,,,,,
  def headerthree(head)
#   raise FreeREGError, "Third line does not start with #,Credit" unless (@csvdata[0] == "#" && (@csvdata[1] == "CREDIT" || @csvdata[1] == "credit" ))
    raise FreeREGError, "The credit person name #{@csvdata[2]} can only contain alphabetic and space characters in the third header line" unless cleanname(2)
    head [:credit_name] = @csvdata[2]
    # # suppressing for the moment
    # address = EmailVeracity::Address.new(@csvdata[3])
    # raise FreeREGError, "Invalid email address '#{@csvdata[3]}' for the credit person in the third line of header" unless address.valid? || @csvdata[3].nil?
    head [:credit_email] = @csvdata[3]
  end

  #process the header line 4
  # eg #,05-Feb-2006,data taken from computer records and converted using Excel
  def headerfour(head)
    raise FreeREGError, "Forth line does not start with # it has #{@csvdata[0]}"  unless (@csvdata[0] == "#")
    raise FreeREGError, "The date of the modification #{@csvdata[1]} in the forth header line is in the wrong format" unless datevalmod(@csvdata[1])
    head [:modification_date] = @csvdata[1]
    head [:first_comments] = @csvdata[2]
    head [:second_comments] = @csvdata[3]
  end

  #process the optional header line 5
  #eg +LDS,,,,
  def headerfive(head)
    if @csvdata[0] == "+LDS"
      head[:lds] = "yes"
    else
      head [:lds]  = "no"
    end
  end
  #process the first 4 columns of the data record
  # County, Place, Church, Reg #

  def datalocation(n,data_record)
    raise FreeREGError, "The county code #{ @csvdata[0]} in the file name is invalid " unless ChapmanCode::values.include?(@csvdata[0])
    data_record[:county] = @csvdata[0]
    # do we validate the Place field?
    raise FreeREGError, "Place field #{@csvdata[1]} in line #{n} contains non numeric characters" unless validregister(@csvdata[1])
    data_record[:place] = @register
    # do we validate the register field 
    raise FreeREGError, "Register field #{@csvdata[2]} in line #{n} contains non numeric characters" unless validregister(@csvdata[2])
    data_record[:register] = @register
    data_record[:register_type] = @register_type
    # need to add the transcriberID
    data_record[:line] = n.to_s + "." + File.basename(@filename.upcase) + "." + @userid
    raise FreeREGError, "Register Entry Number #{@csvdata[3]} in line #{n} contains non numeric characters" if @csvdata[3] =~/\D/
    data_record[:register_entry_nuber] = @csvdata[3]

  end

  #process the baptism record columns
  def databa(n,data_record,head)
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
    data_record[:father_surname_soundex] = addsoundex(10)
    data_record[:mother_surname_soundex] = addsoundex(11)
    head[:datemax] = @datemax
    head[:datemin] = @datemin
    head[:daterange] = @datepop
    if head[:lds] == "yes" then
      data_record[:film] = @csvdata[15]
      data_record[:film_number] = @csvdata[16]
    end
  end
  #process the marriage data columns

  def datama(n,data_record,head)
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
    raise FreeREGError, "The groom's condition #{@csvdata[9]} contains unknown condition #{@csvdata[9]} in line #{n}" unless cleancondition(9)
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
    raise FreeREGError, "The bride's condition #{@csvdata[16]} contains unknown condition in line #{n}" unless cleancondition(16)
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
    data_record[:groom_surname_soundex] = Text::Soundex.soundex(@csvdata[6])
    data_record[:groom_surname_soundex] = "Z000" if (@csvdata[6].nil? ||  Text::Soundex.soundex(@csvdata[6]).nil?)
    data_record[:bride_surname_soundex] = Text::Soundex.soundex(@csvdata[13])
    data_record[:bride_surname_soundex] = "Z000" if (@csvdata[13].nil? ||  Text::Soundex.soundex(@csvdata[13]).nil?)
    data_record[:groom_father_surname_soundex] = Text::Soundex.soundex(@csvdata[20])
    data_record[:groom_father_surname_soundex] = "Z000" if (@csvdata[20].nil? ||  Text::Soundex.soundex(@csvdata[20]).nil?)
    data_record[:bride_father_surname_soundex] = Text::Soundex.soundex(@csvdata[23])
    data_record[:bride_father_surname_soundex] = "Z000" if (@csvdata[23].nil? ||  Text::Soundex.soundex(@csvdata[23]).nil?)
    data_record[:first_witness_surname_soundex] = Text::Soundex.soundex(@csvdata[26])
    data_record[:first_witness_surname_soundex] = "Z000" if (@csvdata[26].nil? ||  Text::Soundex.soundex(@csvdata[26]).nil?)
    data_record[:second_witness_surname_soundex] = Text::Soundex.soundex(@csvdata[28])
    data_record[:second_witness_surname_soundex] = "Z000" if (@csvdata[28].nil? ||  Text::Soundex.soundex(@csvdata[28]).nil?)
    head[:datemax] = @datemax
    head[:datemin] = @datemin
    head[:daterange] = @datepop
    if head[:lds] == "yes"  then
      data_record[:film] = @csvdata[30]
      data_record[:film_number] = @csvdata[31]
    end
  end

  #process the burial data columns
  def databu(n,data_record,head)
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
    data_record[:relative_surname_soundex] = Text::Soundex.soundex(@csvdata[9])
    data_record[:relative_surname_soundex] = "Z000" if (@csvdata[9].nil? ||  Text::Soundex.soundex(@csvdata[9]).nil?)
    data_record[:burial_person_surname_soundex] = Text::Soundex.soundex(@csvdata[10])
    data_record[:burial_person_surname_soundex] = "Z000" if (@csvdata[10].nil? ||  Text::Soundex.soundex(@csvdata[10]).nil?)
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

  end

  def create_or_update_db_record_for_file(head)
    if @freereg1_csv_file
      @freereg1_csv_file.update_attributes!(head)      
    else
      @freereg1_csv_file = Freereg1CsvFile.create!(head)
    end
  end

  def self.delete_all
    Freereg1CsvEntry.delete_all
    Freereg1CsvFile.delete_all
  end


  def self.process(filename)
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
  #      filename = "NFKGYAMA.CSV"
  
  #     fileout =  "test_data/csvout/" + user_dirname + "/" + standalone_filename.sub(File.extname(standalone_filename), '.out')
  #     FileUtils.mkdir_p(File.dirname(fileout))
       filewarn = "test_data/warning/messages.log"
       FileUtils.mkdir_p(File.dirname(filewarn) )
       mesout = File.new(filewarn, "a")
          
#    dataout = File.new(fileout, "wb")
        header = Hash.new
        data_record = Hash.new
        header[:file_name] = standalone_filename #do not capitalize filenames
        header[:userid] = user_dirname
        me = FreeregCsvProcessor.new(filename,user_dirname)
    
    #deal with the headers
        me.getvalidline
        me.headerone(header)
        me.getvalidline
        me.headertwo(header)
        me.getvalidline
        me.headerthree(header)
        me.getvalidline
        me.headerfour(header)
        me.getvalidline
        me.headerfive(header)
        # persist the record for the file
        me.create_or_update_db_record_for_file(header)
    #deal with the data    
        n = 1
    #deal with header 5 being optional
        type = header[:record_type]
        me.getvalidline  if header[:lds] == 'yes'
    #keep going until we run out of data    
        loop do
          me.datalocation(n,data_record)
          case type
            when Freereg1CsvFile::RECORD_TYPES::BAPTISM then me.databa(n,data_record,header)
            when Freereg1CsvFile::RECORD_TYPES::MARRIAGE then me.datama(n,data_record,header)
            when Freereg1CsvFile::RECORD_TYPES::BURIAL then me.databu(n,data_record,header)                      
          end
      #store the processed data   
 #         dataout.puts data_record
          me.create_db_record_for_entry(data_record)
          n = n + 1
          me.getvalidline
      #   break if n == 6
        end
    #rescue the freereg data errors
    rescue FreeREGError => free
      puts free.message
      mesout.puts free.message
      mesout.puts "*********************** #{n} ***********#{standalone_filename} ***********#{user_dirname}" 
    #rescue the end of file and close out the file
    rescue FreeREGEnd => free
      n = n-1

      header[:records] = n
      header[:county] = data_record [:county]   
      header[:place] = data_record [:place]
      header[:register] = data_record [:register]
      header[:register_type] = data_record[:register_type]

      puts " Processed #{n} lines" 
    # print the header and add it to the processed records
    #  puts header
    #  dataout.puts header
    #  dataout.close
    me.create_or_update_db_record_for_file(header)
    rescue Exception => e 
      puts e.message
      mesout.puts "*********************** #{n} ***********#{standalone_filename} **************#{user_dirname}       "  
      mesout.puts e.message  
      mesout.puts e.backtrace.inspect  
    end 


    
  end


end
#set the FreeREG error conditions
class FreeREGError < StandardError
end

class FreeREGEnd < StandardError
end
# 
# require 'pry'


