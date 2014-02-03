class FreeregCsvProcessor
#coding: utf-8

  require "csv"
  require 'email_veracity'
  require 'text'
  require "unicode"
  require 'chapman_code'
 require "#{Rails.root}/app/models/freereg1_csv_file"
  require "record_type"
  require 'digest/md5'
  require 'get_files'
 
  CONTAINS_PERIOD = /\./
  DATEMAX = 2020
  DATEMIN = 1530
  HEADER_FLAG = /\A\#\z/
  ST_PERIOD = /\A[Ss][Tt]\z/
  VALID_AGE_MAXIMUM = {'d' => 100, 'w' => 100 , 'm' => 100 , 'y' => 120}
  VALID_AGE_TYPE1 = /\A\d{1,3}\z/
  VALID_AGE_TYPE2 = /^(\d{1,2})([dwmy])/
  VALID_AGE_TYPE3 =  /^(\d{1,2})([dwmy])(\d{1,2})([dwmy])/
  VALID_AGE_TYPE4 = /\A [[:xdigit:]] \z/
  VALID_AGE_WORDS = ["infant", "child", "minor", "of age","full age","of full age"]
  VALID_CHAR = /[^a-zA-Z\d\!\+\=\_\&\?\*\)\(\]\[\}\{\'\" \.\,\;\/\:\r\n\@\$\%\^\-\#]/
  VALID_DAY = /\A\d{1,2}\z/
  VALID_MONTH = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP","SEPT", "OCT", "NOV", "DEC", "*","JANUARY","FEBRUARY","MARCH","APRIL","MAY","JUNE","JULY","AUGUST","SEPTEMBER","OCTOBER","NOVEMBER","DECEMBER"]
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
  VALID_DATE = /^\d{1,2}.[A-Za-z]{3,3}.\d{4}$/
  VALID_DATE_SHORT = /^\d{1,2}.[A-Za-z]{3,3}.\d{2}$/
  VALID_DATE_NUMERIC = /^\d{1,2}.\d{1,2}.\d{2}$/
  VALID_CCC_CODE = /\A[CcSs]{3,6}\z/
  VALID_CREDIT_CODE = ["CREDIT", "Credit", "credit"]
  VALID_NAME = /[^A-Za-z\)\(\]\[\}\{\?\*\'\"\ \.\,\;\:\_]/
  VALID_TEXT = /[^A-Za-z\)\(\]\[\}\{\?\*\'\"\ \.\,\;\:\_\!\+\=]/
  VALID_MALE_SEX = ["M","M." ,"SON","MALE","MM","SON OF"]
  UNCERTAIN_MALE_SEX = ["M?","SON?","[M]" ,"MF"]
  UNCERTAIN_FEMALE_SEX = ["F?", "DAU?"]
  UNCERTAIN_SEX = ["?", "-", "*","_","??"]
  VALID_FEMALE_SEX = ["F","FF","FFF","FM","F.","FEMALE","DAUGHTER","WIFE","DAUGHTER OF","DAU", "DAU OF"]
  VALID_REGISTER_TYPES = /\A[AaBbDdEeTtPp\(][AaBbDdEeHhTtPpTtXxRrWw]?[TtXxRrWw]?'?[Ss]? ?[\)]?\z/
  VALID_REGISTER_TYPE = ["AT", "BT", "PR", "PH", "EX", "TR", "DW", "DT", "PT", "MI"]
  WILD_CHARACTER = /[\*\[\]\-\_\?]/
  CHURCH_WORD_EXPANSIONS =  {
            'Albans' => 'Alban',
            'Albright\'s' => 'Albright',
            'Andrews' => 'Andrew',
            'Andrew\'s' => 'Andrew',
            'Annes' => 'Anne',
            'Augustines' => 'Augustine',
            'Augustine\'s' => 'Augustine',
            'Barthlomew' => 'Bartholomew',
            'Bartholemew' => 'Bartholomew',
            'Bartholemews' => 'Bartholomew',
            'Batholomew' => 'Bartholomew',
            'Batholomews' => 'Bartholomew',
            'Benedict\'s' => 'Benedict',
            'Benedicts' => 'Benedict',
            'Bololph' => 'Botolph',
            'Boltolph' => 'Botolph',
            'Boltoph' => 'Botolph',
            'Boltophs' => 'Botolph',
            'Botoph' => 'Botolph',
            'Catherines' => 'Catherine',
            'Catherine\'s' => 'Catherine',
            'Chads' => 'Chad',
            'Clements' => 'Clement',
            'Clement\'s' => 'Clement',
            'Cuthberts' => 'Cuthbert',
            'Davids' => 'David',
            'David\'s' => 'David',
            'Dunstans' => 'Dunstan',
            'Edmonds' => 'Edmond',
            'Edmunds' => 'Edmund',
            'Edwards' => 'Edward',
            'Edward\'s' => 'Edward',
            'Elphins' => 'Elphin',
            'Faiths' => 'Faith',
            'Georges' => 'George',
            'George\'s' => 'George',
            'Germans' => 'German',
            'Guthlac\'s' => 'Guthlac',
            'Helens' => 'Helen',
            'Helen\'s' => 'Helen',
            'Johns' => 'John',
            'Julians' => 'Julian',
            'Leonards' => 'Leonard',
            'Loenard\'s' => 'Loenard',
            'Lukes' => 'Luke',
            'Margarets' => 'Margaret',
            'Margaret\'s' => 'Margaret',
            'Marks' => 'Mark',
            'Martins' => 'Martin',
            'Martin\'s' => 'Martin',
            "Marys" => 'Mary',
            'Mary\'s' => 'Mary',
            'Matthews' => 'Matthew',
            'Michaels' => 'Michael',
            'Michael\'s' => 'Michael',
            'Oswalds' => 'Oswald',
            'Pauls'=> 'Paul',
            'Paul\'s' => 'Paul',
            'Pega\'s' => 'Pega',
            'Peters' => 'Peter',
            'Peter\'s' => 'Peter',
            'Philips' => 'Philip',
            'Stevens' => 'Steven',
            'Steven\'s' => 'Steven',
            
            'Swithen' => 'Swithin',
            'Swithins' => 'Swith1n',
            'Swithin\'s' => 'Swithin',
            'Swithuns' => 'Swithun',
            'Wilfreds' => 'Wilfred',
            'Wilfrid\'s' => 'Wilfrid',
            'Cemetry' => 'Cemetery',
            'Marys' => 'Mary',
            "Mary\'s" => 'Mary',
            "Marys\'" => 'Mary',
             'Nicholas\'' => 'Nicholas'}
COMMON_WORD_EXPANSIONS = {
             'Saints\'' => 'St',
            'Saint\'s' => 'St',
            'Saint' => 'St',
            'SAINT' => 'St',
            'St.' => 'St',
            'ST' => 'St',
            'Gt' => 'Great',
            'GT' => 'Great',
            'Gt.' => 'Great',
            'GT.' => 'Great',
            'Lt' => 'Little',
            'LT' => 'Little',
            'Lt.' => 'Little',
            'LT.' => 'Little',
            '&' => "and",
            'NR' => 'near',
            'nr' => 'near',
            }
  WORD_SPLITS = {
            "-" => /\-/, 
            "&" => /\&/}
  DATE_SPLITS = {
            " " => /\s/,
            "-" => /\-/,
            "/" => /\\/}
  CAPITALIZATION_WORD_EXCEPTIONS = [
            "a", "an", "and", "at", "but", "by", "cum", "de", "for", "has", "in", "la", "le", "near", "next", "nor", "nr", "or", "on", "of", "so", 
            "the", "to", "von", "with", "yet", "y"]
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

  attr_accessor :freereg1_csv_file


  # validate the modern date of creation or modification
  def self.datevalmod(m)
    return true if @csvdata[m].nil? || @csvdata[m].empty?
    if @csvdata[m] =~ VALID_DATE_SHORT 
         DATE_SPLITS.each_pair do |date_splitter, date_split|
          date_parts = @csvdata[m].split(date_split)
          if date_parts.length == 3 then
            date_parts[2] = (date_parts[2].to_i + 2000).to_s 
          end
          @csvdata[m] = date_parts.join(" ")
        end
        return true
    else
        if @csvdata[m] =~ VALID_DATE 
         DATE_SPLITS.each_pair do |date_splitter, date_split|
          date_parts = @csvdata[m].split(date_split)
          @csvdata[m] = date_parts.join(" ") if date_parts.length == 3
          end
          return true
        else
          if @csvdata[m] =~ VALID_DATE_NUMERIC 
            DATE_SPLITS.each_pair do |date_splitter, date_split|
             date_parts = @csvdata[m].split(date_split)
             if date_parts.length == 3 then
              date_parts[1] = VALID_MONTH[date_parts[1].to_i ]
              date_parts[2] = (date_parts[2].to_i + 2000).to_s 
              @csvdata[m] = date_parts.join(" ") 
             
             end
            end
            return true
          else
           return false 
        end
         return false 
        end
    end
  end

  #calculate the minimum and maximum dates in the file; also populate the decadal content table starting at 1530
  def self.datestat(x)
    return true if x.nil? || x.empty?
      xx = x.to_i
      daterange = Array.new
       datemax = @@list_of_registers[@@place_register_key].fetch(:datemax)
       datemin = @@list_of_registers[@@place_register_key].fetch(:datemin)
       daterange = @@list_of_registers[@@place_register_key].fetch(:daterange)
      datemax = xx if xx > datemax
      datemin = xx if xx < datemin
      xx = (xx-1530)/10 unless xx <= 1530 # avoid division into zero
      daterange[xx] = daterange[xx] + 1 unless (xx < 0 || xx > 50) #avoid going outside the data range array
      @@list_of_registers[@@place_register_key].store(:datemax,datemax)
      @@list_of_registers[@@place_register_key].store(:datemin,datemin)
      @@list_of_registers[@@place_register_key].store(:daterange,daterange)
  end

  #validate dates in the record and allow for the split date format 1567/8 and 1567/68 creates a base year and a split year eg /8
  def self.datevalsplit(x,type_of_date)
    @splityear = nil
    return true if x.nil? || x.empty?
      a = x.split(" ")
      if a.length == 3
        #work with  dd mmm yyyy/y
        #firstly deal with the dd and allow the wild character
        return false unless (a[0].to_s =~ VALID_DAY || a[0].to_s =~ WILD_CHARACTER)
        #deal with the month allowing for the wild character
        return false unless (VALID_MONTH.include?(Unicode::upcase(a[1])) || a[1].to_s =~ WILD_CHARACTER)
          #deal with the year and split year
          if a[2].length >4
            #deal with the split year
             @splityear = a[2]
              a[2]= a[2][0..-(a[2].length-3)]
              @splityear = @splityear[-(@splityear.length-4)..-1]
              datestat(a[2]) unless  (a[2].to_s =~ WILD_CHARACTER || type_of_date == "Birth")
              return true
          else
              #deal with the yyyy and permit the wild character
              return false  unless (a[2].to_s =~ VALID_YEAR || a[2].to_s =~ WILD_CHARACTER)
              datestat(a[2]) unless  (a[2].to_s =~ WILD_CHARACTER || type_of_date == "Birth")
              return true
          end
      else
        if a.length == 2
         #deal with dates that are mmm yyyy firstly the mmm then the split year
          return false unless (VALID_MONTH.include?(Unicode::upcase(a[0])) || a[0].to_s =~ WILD_CHARACTER)
            if a[1].length >4
              @splityear = a[1]
              a[1]= a[1][0..-(a[1].length-3)]
              @splityear = @splityear[-(@splityear.length-4)..-1]
              datestat(a[1]) unless (a[1].to_s =~ WILD_CHARACTER || type_of_date == "Birth")
              return true
            else
              return false  unless (a[1].to_s =~ VALID_YEAR || a[1].to_s =~ WILD_CHARACTER)
              datestat(a[1]) unless  (a[1].to_s =~ WILD_CHARACTER || type_of_date == "Birth")
              return true
            end
        else
          if a.length == 1
          #deal with dates that are year only
            if a[0].length >4
              @splityear = a[0]
              a[0]= a[0][0..-(a[0].length-3)]
              @splityear = @splityear[-(@splityear.length-4)..-1]
              datestat(a[0]) unless  (a[0].to_s =~ WILD_CHARACTER || type_of_date == "Birth")
              return true
            else
              return false  unless (a[0].to_s =~ VALID_YEAR || a[0].to_s =~ WILD_CHARACTER)
              datestat(a[0]) unless  (a[0].to_s =~ WILD_CHARACTER || type_of_date == "Birth")
              return true
            end
          end        
        end
      end
  end

  # clean up names
  def self.cleanname(m)
    #not convinced this code is effective or needed
    return true if @csvdata[m].nil? || @csvdata[m].empty?
    return true if @csvdata[m] !=~ VALID_NAME
    return false
  end

  #clean up the sex field
  def self.cleansex(m)
    return true if @csvdata[m].nil? || @csvdata[m].empty?
    case
    when VALID_MALE_SEX.include?(@csvdata[m].upcase)
     @csvdata[m] = "M" 
     return true 
    when UNCERTAIN_MALE_SEX.include?(@csvdata[m].upcase)
      @csvdata[m] = "M?" 
      return true 
    when VALID_FEMALE_SEX.include?(@csvdata[m].upcase)
     @csvdata[m] = "F"
     return true  
    when UNCERTAIN_FEMALE_SEX.include?(@csvdata[m].upcase)
     @csvdata[m] = "F?"
     return true  
    when UNCERTAIN_SEX.include?(@csvdata[m].upcase)
     @csvdata[m] = "?" 
     return true 
    else
      return false
    end
  end

  #clean up a text field eg abode and notes fields
  def self.cleantext(m)
     #not convinced this code is effective or needed
    return true if @csvdata[m].nil? || @csvdata[m].empty?
      return true if @csvdata[m] !=~ VALID_TEXT
      return false
  end

  # clean u the conditions field and make changes according to the valconditions hash
  def self.cleancondition(m)
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
  def self.cleanage(m)
     #the planning team requested this code be deactivated
    return true if @csvdata[m].nil? || @csvdata[m].empty?
      #test for valid words
      return true if VALID_AGE_WORDS.include?(Unicode::downcase(@csvdata[m]))
      #test for straight years
     
        if @csvdata[m] =~ VALID_AGE_TYPE1
          return true unless @csvdata[m].to_i > VALID_AGE_MAXIMUM["y"]
          return false
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
  def self.charvalid(m)
   return true if (m == "iso-8859-1"  || m.nil? || m.empty? || m == "chset")
     #Deal with the cp437 code which is not in ruby also deal with the macintosh instruction in freereg1
      m = "IBM437" if (m == "cp437")
      m = m.upcase
      m = "macRoman" if (m.downcase == "macintosh")
      raise FreeREGError,  "Invalid Character Set" unless @code_sets.include?(m) 
      if Encoding.find(m)
        #if we have valid new character set; use it and change the file encoding
        @@charset = Encoding.find(m)
        
         @@array_of_data_lines = CSV.read(@@file, external_encoding:@@charset , internal_encoding:"UTF-8")                              
        
        return true
      else
        return false
      end
  end

  def self.mycapitalize(word,num,type_of_name)
    word = CHURCH_WORD_EXPANSIONS[word] if CHURCH_WORD_EXPANSIONS.has_key?(word) && type_of_name == "Church"
    word = COMMON_WORD_EXPANSIONS[word] if COMMON_WORD_EXPANSIONS.has_key?(word)
    word = Unicode::downcase(word) 
    word = Unicode::capitalize(word) unless CAPITALIZATION_WORD_EXCEPTIONS.include?(word) 
    word = Unicode::capitalize(word) if num == 0
    return word
  end

  def self.validregister(m,type_of_name)
    #cleans up Church and Place names
    @register = nil
    @register_type = nil
    return true if m.nil? || m.empty?
    m = m.gsub(/\(?\)?/, '')
    register_words = m.split(" ")
    n = register_words.length

    #register_words[-1] = register_words[-1].gsub(/\(?\)?/, '')
   
    if (type_of_name == "Church" ) then
      if n > 1
        if register_words[-1] =~ VALID_REGISTER_TYPES then 
          # extract a Register Type field from the church field
          register_words[-1] = register_words[-1].gsub(/'?"?[Ss]?/, '')
          register_words[-1] = Unicode::upcase(register_words[-1])
      
         if VALID_REGISTER_TYPE.include?(register_words[-1]) 
          # check that it is a valid code
           @register_type = register_words[-1]
           n = n - 1
           @register_type = "DW" if @register_type == "DT"
           @register_type = "PH" if @register_type == "PT"
          else
           raise FreeREGError,  "The apparent Register Type extracted from the Church name #{register_words[-1]} is not valid" 
         end
        end
      end
    
     #deal with a missing space between St.Name in a church name
     
      if (register_words[0] =~ CONTAINS_PERIOD) && (register_words[0].length) > 3 then
        register_first_word_parts = register_words[0].partition(CONTAINS_PERIOD)
        if register_first_word_parts[0] =~ ST_PERIOD then
          register_words.shift
          register_words.insert(0,register_first_word_parts[2])
          register_words.insert(0,register_first_word_parts[0])
         
          n = n + 1
        end
      end
    end
   #now clean up multi word names with - and & as seperators
    idone = Array.new
    ii = 0
     while ii <10
      idone[ii] = nil
      ii = ii + 1
    end
      WORD_SPLITS.each_pair do |word_splitter, word_split|
       i = 0
       ii = 0
       while i < n do 
        register_word_parts = register_words[i].split(word_split)
        if register_word_parts.length > 1
          while ii < register_word_parts.length
            register_word_parts[ii] = mycapitalize(register_word_parts[ii],ii,type_of_name)
            ii = ii + 1
          end
          register_words[i] = register_word_parts.shift(register_word_parts.length).join(word_splitter)
          idone[i] = 'done'
          
         else
          register_words[i] = mycapitalize(register_words[i],i,type_of_name) if idone[i].nil?
          
          idone[i] = 'done'
         end
       i = i + 1
      end

    end
    @register = register_words.shift(n).join(' ')
   
    return true
  end

  #get a line of data
  def self.get_line_of_data
     @csvdata = @@array_of_data_lines[@@number_of_line]
    raise FreeREGEnd,  "End of file" if @csvdata.nil?
    @csvdata.each_index  {|x| @csvdata[x] = @csvdata[x].gsub(/zzz/, ' ').gsub(/\s+/, ' ').strip unless @csvdata[x].nil? }
    raise FreeREGError,  "Empty data line" if @csvdata.empty? || @csvdata[0].nil?
    @first_character = "?"
    @first_character = @csvdata[0].slice(0) unless  @csvdata[0].nil?
    @line_type = "Data"
    @line_type = "Header" if (@first_character == '+' || @first_character ==  '#')
    number_of_fields = @csvdata.length
    number_empty = 1
      @csvdata.each do |l|
         number_empty = number_empty + 1 if l.nil? || l.empty?
      end
    #      puts " #{@@number_of_line} #{@line_type} #{first_character} #{number_of_fields} #{number_empty} "
    raise FreeREGError,  "The data line has only 1 field" if number_empty == number_of_fields && @line_type == "Data"
    return @line_type
  end

  #process the header line 1
  # eg +INFO,David@davejo.eclipse.co.uk,password,SEQUENCED,BURIALS,cp850,,,,,,,
  def self.process_header_line_one
    raise FreeREGError,  "First line of file does not start with +INFO it has #{@csvdata[0]}" unless ((@csvdata[0] == "+INFO") || (@csvdata[0] == "#NAME?"))
    # BWB: temporarily commenting out to test db interface
#   address = EmailVeracity::Address.new(@csvdata[1])
#   raise FreeREGError,  "Invalid email address #{@csvdata[1]} in first line of header" unless address.valid?
    @@header [:transcriber_email] = @csvdata[1]
    raise FreeREGError,  "Invalid file type #{@csvdata[4]} in first line of header" unless VALID_RECORD_TYPE.include?(@csvdata[4].gsub(/\s+/, ' ').strip.upcase)
    # canonicalize record type
    raw_record_type = @csvdata[4]
    scrubbed_record_type = Unicode::upcase(@csvdata[4]).gsub(/\s/, '')
    @@header [:record_type] =  RECORD_TYPE_TRANSLATION[scrubbed_record_type]
    raise FreeREGError, "Invalid characterset #{@csvdata[5]} in the first header line" unless charvalid(@csvdata[5])
    @@header [:characterset] = @csvdata[5]
  end

  #process the header line 2
  # eg #,CCCC,David Newbury,Derbyshire,dbysmalbur.CSV,02-Mar-05,,,,,,,
  def self.process_header_line_two
    @csvdata = @csvdata.compact
    @number_of_fields = @csvdata.length
    raise FreeREGError, "The second header line is completely empty; please check the file for blank lines" if @number_of_fields == 0
    @csvdata[1] = @csvdata[1].upcase unless @csvdata[1].nil?
    case
      when (@csvdata[0] =~ HEADER_FLAG && @csvdata[1] =~ VALID_CCC_CODE)
         #deal with correctly formatted header

         process_header_line_two_block
      when @number_of_fields == 1 && @csvdata[0] =~ HEADER_FLAG
     #empty line    
      when (@number_of_fields == 4) && (@csvdata[0].length > 1)
        #deal with #transcriber
        i = 0
        while i < 4  do
          @csvdata[5-i] = @csvdata[3-i]
          i +=1
        end
        @csvdata[2] = @csvdata[2].gsub(/#/, '')        
        process_header_line_two_block
    when (@number_of_fields == 4) && (@csvdata[0] =~ HEADER_FLAG)
      # missing a field somewhere; assume date and fiile name are there and put other field in the transcriber
     @csvdata[5] = @csvdata[3]
      @csvdata[4] = @csvdata[2]
      @csvdata[2] = @csvdata[1]
      process_header_line_two_block 
    when (@number_of_fields == 5) && (@csvdata[1].length > 1) && @csvdata[0] =~ HEADER_FLAG
      #,transciber,syndicate,file,date
      @csvdata[5] = @csvdata[4]
      @csvdata[4] = @csvdata[3]
      @csvdata[3] = @csvdata[2]
      @csvdata[2] = @csvdata[1]
      process_header_line_two_block
    when (@number_of_fields == 5) && (@csvdata[0].length > 1) 
      #deal with missing , between #and ccc
      @csvdata[5] = @csvdata[4]
      @csvdata[4] = @csvdata[3]
      @csvdata[3] = @csvdata[2]
      @csvdata[2] = @csvdata[1]
      process_header_line_two_block 

    when (@number_of_fields == 6) && (@csvdata[1].length > 1) && @csvdata[0].slice(0) =~ HEADER_FLAG
      #,transciber,syndicate,file,date,
      process_header_line_two_block 
    when (@number_of_fields == 6) && (@csvdata[1].length > 1) && @csvdata[0] =~ HEADER_FLAG
      ##,XXXX,David Newbury,Derbyshire,dbysmalbur.CSV,02-Mar-05,
       process_header_line_two_block   
    when @number_of_fields == 7
      eric = Array.new
    #the basic EricD format #,Eric Dickens,Gloucestershire Bisley MA,GLSBISMA.csv,GLSBISMA.csv,28-Oct-2008,CSV

      eric[2] = @csvdata[1]
      eric[3] = @csvdata[2]
      eric[4] = @csvdata[4]
      eric[5] = @csvdata[5]
      i = 2
      while i < 6  do
        @csvdata[i] = eric[i]
        i +=1
      end
      process_header_line_two_block
        
    else
      raise FreeREGError, "I did not know enough about your data format to extract transciber information at header line 2"
      
    end
  
  end

  def self.process_header_line_two_block
    raise FreeREGError, "The transcriber's name #{@csvdata[2]} can only contain alphabetic and space characters in the second header line" unless cleanname(2)
    @@header [:transcriber_name] = @csvdata[2]
    raise FreeREGError, "The syndicate can only contain alphabetic and space characters in the second header line" unless cleanname(2)
    @@header [:transcriber_syndicate] = @csvdata[3]
     raise FreeREGError, "The transcription date #{@csvdata[5]} is incorrectly formatted" unless datevalmod(5)
    @@header [:transcription_date] = @csvdata[5]
  end

  #process the @@headerer line 3
  # eg #,Credit,Libby,email address,,,,,,
  def self.process_header_line_threee
     @csvdata = @csvdata.compact
     @number_of_fields = @csvdata.length
     raise FreeREGError, "The third header line is completely empty; please check the file for blank lines" if @number_of_fields == 0
    
    case 
      when (@csvdata[0] =~ HEADER_FLAG &&  VALID_CREDIT_CODE.include?(@csvdata[1]))
        #the normal case 
        process_header_line_three_block
      when @number_of_fields == 1 && @csvdata[0] =~ HEADER_FLAG
        #no information just keep going
      
      when @number_of_fields == 2 && !VALID_CREDIT_CODE.include?(@csvdata[1])
         #eric special #,Credit name
         a = @csvdata[1].split(" ") 
         @@header [:credit_name] = a[1] if a.length == 1
         a = a.drop(1)
         @@header [:credit_name] = a.join(" ")
      when @number_of_fields == 3 && !VALID_CREDIT_CODE.include?(@csvdata[1])
         #,Credit name,
         @@header [:credit_name] = @csvdata[1] if !@csvdata[1].length == 1
      when @number_of_fields == 4 && !VALID_CREDIT_CODE.include?(@csvdata[1])
         #,Credit name,,
         @@header [:credit_name] = @csvdata[1] if !@csvdata[1].length == 1

      when ((@number_of_fields == 5) && (@csvdata[1].nil?))
          #and extra comma
          @csvdata[2] = @csvdata[3]
          @csvdata[3] = @csvdata[4]
          process_header_line_three_block
      else
        raise FreeREGError, "I did not know enough about your data format to extract Credit Information at header line 3"
    end
  
  end

  def self.process_header_line_three_block
    raise FreeREGError, "The credit person name #{@csvdata[2]} can only contain alphabetic and space characters in the third header line" unless cleanname(2)
    @@header [:credit_name] = @csvdata[2]
    # # suppressing for the moment
    # address = EmailVeracity::Address.new(@csvdata[3])
    # raise FreeREGError, "Invalid email address '#{@csvdata[3]}' for the credit person in the third line of header" unless address.valid? || @csvdata[3].nil?
    @@header [:credit_email] = @csvdata[3]
    
  end

  #process the header line 4
  # eg #,05-Feb-2006,data taken from computer records and converted using Excel, LDS
  def self.process_header_line_four
    @csvdata = @csvdata.compact
    @number_of_fields = @csvdata.length
     raise FreeREGError, "The forth header line is completely empty; please check the file for blank lines" if @number_of_fields == 0
      case 
        when (@number_of_fields == 4 && @csvdata[0] =~ HEADER_FLAG && datevalmod(1))
         #standard format
          @@header [:modification_date] = @csvdata[1]
          @@header [:first_comment] = @csvdata[2]
          @@header [:second_comment] = @csvdata[3]
       when (@number_of_fields == 1 && @csvdata[0] =~ HEADER_FLAG)
          # an empty line follows the #
       when (@number_of_fields == 1 && @csvdata[0] !=~ HEADER_FLAG)
        # is an # folloed by something either  date or a comment
          a = Array.new
          a = @csvdata[0].split("")
          if a[0] =~ HEADER_FLAG
             a = a.drop(1)
             @csvdata[0] = a.join("").strip
             if datevalmod(0) == true
               @@header [:modification_date] = @csvdata[0]
             else
               @@header [:first_comment] = @csvdata[0]                
             end
          else
            @@header [:modification_date] = @@header [:transcription_date]
             raise FreeREGError, "I did not know enough about your data format to extract notes Information at header line 4"
            
          end
       when (@number_of_fields == 2 && @csvdata[0] =~ HEADER_FLAG && datevalmod(1))
           #date and no notes
           @@header [:modification_date] = @csvdata[1]
       when @number_of_fields == 2 && @csvdata[0] =~ HEADER_FLAG
          # only a single comment
          @@header [:first_comment] = @csvdata[1]  
       when @number_of_fields == 2 && !(@csvdata[0] =~ HEADER_FLAG)
          #date only a single comment but no comma ith date in either field
          a = Array.new
          a = @csvdata[0].split("")
          if a[0] =~ HEADER_FLAG
             a = a.drop(1)
             @csvdata[0] = a.join("").strip
              case 
              when datevalmod(0)
               @@header [:modification_date] = @csvdata[0] 
               @@header [:first_comment] = @csvdata[1]
              when datevalmod(1)
                @@header [:modification_date] = @csvdata[1] 
                @@header [:first_comment] = @csvdata[0]
              else
                @@header [:first_comment] = @csvdata[0]
                @@header [:second_comment] = @csvdata[1]
              end
          else
            @@header [:modification_date] = @@header [:transcription_date]
             raise FreeREGError, "I did not know enough about your data format to extract notes Information at header line 4"
           
          end 
       when (@number_of_fields == 3 && @csvdata[0] =~ HEADER_FLAG && datevalmod(1)) 
            # date and one note
           @@header [:modification_date] = @csvdata[1]
           @@header [:first_comment] = @csvdata[2]
       when (@number_of_fields == 3 && @csvdata[0] =~ HEADER_FLAG && datevalmod(2))
            #one note and a date 
            @@header [:modification_date] = @csvdata[2]
            @@header [:first_comment] = @csvdata[1]
       when @number_of_fields == 3  && @csvdata[0] =~ HEADER_FLAG
          # Many comments
          @csvdata.drop(1)
          @@header [:first_comment] = @csvdata.join(" ")
       when (@number_of_fields == 4 && @csvdata[0] =~ HEADER_FLAG && datevalmod(1)) 
            #date and 3 comments
            @@header [:modification_date] = @csvdata[2]
            @csvdata = @csvdata.drop(1)
            @@header [:first_comment] = @csvdata.join(" ")
       when (@number_of_fields == 4 && @csvdata[0] =~ HEADER_FLAG && !datevalmod(1)) 
            # 4 comments one of which may be a date that is not in field 2
            @@header [:first_comment] = @csvdata.join(" ")
       when (@number_of_fields == 5 && @csvdata[0] =~ HEADER_FLAG && datevalmod(1)) 
            #,date and 3 comments
            @@header [:modification_date] = @csvdata[1]
            @csvdata = @csvdata.drop(2)
            @@header [:first_comment] = @csvdata.join(" ")
       
        else
            @@header [:modification_date] = @@header [:transcription_date]
            raise FreeREGError, "I did not know enough about your data format to extract notes Information at header line 4"
            
      end
      @@header [:modification_date] = @@header[:transcription_date] if (@@header [:modification_date].nil? || (Freereg1CsvFile.convert_date(@@header [:transcription_date]) > Freereg1CsvFile.convert_date(@@header [:modification_date])))
      
      @@header [:modification_date] = @@uploaded_date.strftime("%d %b %Y") if (Freereg1CsvFile.convert_date(@@uploaded_date.strftime("%d %b %Y")) > Freereg1CsvFile.convert_date(@@header [:modification_date]))
  end

  #process the optional header line 5
  #eg +LDS,,,,
  def self.process_header_line_five
    if @csvdata[0] == "+LDS"
      @@header[:lds] = "yes"
    else
      @@header [:lds]  = "no"
    end
  end
  #process the first 4 columns of the data record
  # County, Place, Church, Reg #
  def self.setup_or_add_to_list_of_registers(place_register_key,data_record)
      @@datemax = DATEMIN
      @@datemin = DATEMAX
     @@daterange = Array.new(50){|i| i * 0 }
      @number_of_records = 0
     
      @@list_of_registers[place_register_key] = Hash.new
      @@data_hold[place_register_key] = Hash.new
       @@list_of_registers[place_register_key].store(:county,data_record[:county])
        @@list_of_registers[place_register_key].store(:place,data_record[:place])
         @@list_of_registers[place_register_key].store(:church_name,data_record[:church_name])
          @@list_of_registers[place_register_key].store(:register_type,data_record[:register_type])
          @@list_of_registers[place_register_key].store(:alternate_register_name,data_record[:alternate_register_name])
           @@list_of_registers[place_register_key].store(:records,@number_of_records)
            @@list_of_registers[place_register_key].store(:datemax,@@datemax)
             @@list_of_registers[place_register_key].store(:datemin,@@datemin)
              @@list_of_registers[place_register_key].store(:daterange,@@daterange)
 
  end

  def self.process_register_location(n)
    data_record = Hash.new
    raise FreeREGError, "Empty data line"  if @csvdata[0].nil? 
    raise FreeREGError, "The county code #{ @csvdata[0]} is invalid or you have a blank record line " unless ChapmanCode::values.include?(@csvdata[0])
   
    # do we validate the Place field?
    raise FreeREGError, "Place field #{@csvdata[1]} contains non numeric characters" unless validregister(@csvdata[1],"Place")
    data_record[:place] = @register
    # do we validate the register field 
    raise FreeREGError, "Register field #{@csvdata[2]} contains non numeric characters" unless validregister(@csvdata[2],"Church")
    data_record[:county] = @csvdata[0]
    data_record[:church_name] = @register
    data_record[:register_type] = @register_type
   
    data_record[:county] = "Blank" if data_record[:county].nil?
    data_record[:place] = "Blank" if data_record[:place].nil?
    data_record[:church_name] = "Blank" if data_record[:church_name].nil?
    data_record[:register_type] = " " if data_record[:register_type].nil?
    data_record[:alternate_register_name] = @register.to_s + " " + data_record[:register_type].to_s
        # need to add the transcriberID
    #puts "header #{data_record[:county]}, #{data_record[:place]}, #{data_record[:church_name]}, #{data_record[:register_type]} "
     place_register_key = data_record[:county] + "." + data_record[:place] + "." + data_record[:church_name] + "." +  data_record[:register_type]
    if  !@@list_of_registers.has_key?(place_register_key ) then
     setup_or_add_to_list_of_registers(place_register_key,data_record)
    end
    @@place_register_key = place_register_key
  end

  #process the baptism record columns
  def self.process_baptism_data_records(n)
    data_record = Hash.new
    data_record[:line_id] = @@userid + "." + File.basename(@@filename.upcase) + "." + n.to_s
    data_record[:file_line_number] = n
    raise FreeREGError, "Register Entry Number #{@csvdata[3]} contains non numeric characters" unless cleantext(3)
    data_record[:register_entry_nuber] = @csvdata[3]
    raise FreeREGError, "The date of the birth #{@csvdata[4]} is in the wrong format" unless datevalsplit(@csvdata[4],"Birth")
    data_record[:birth_date_split] = @splityear
    data_record[:birth_date] = @csvdata[4]
    raise FreeREGError, "The date of the baptism #{@csvdata[5]} is in the wrong format" unless datevalsplit(@csvdata[5],"Baptism")
    data_record[:baptism_date_split] = @splityear
    data_record[:baptism_date] = @csvdata[5]
    raise FreeREGError, "The person's forename #{@csvdata[6]} contains invalid characters" unless cleanname(6)
    data_record[:person_forename] = @csvdata[6]
    raise FreeREGError, "The sex field #{@csvdata[7]} is not M F - or blank" unless cleansex(7)
    data_record[:person_sex] = @csvdata[7]
    raise FreeREGError, "The father's forename #{@csvdata[8]} contains invalid characters" unless cleanname(8)
    data_record[:father_forename] = @csvdata[8]
    raise FreeREGError, "The mother's forename #{@csvdata[9]} contains invalid characters" unless cleanname(9)
    data_record[:mother_forename] = @csvdata[9]
    aise FreeREGError, "The father's surname #{@csvdata[10]} contains invalid characters" unless cleanname(10)
    data_record[:father_surname] = Unicode::upcase(@csvdata[10]) unless @csvdata[10].nil?
    data_record[:father_surname] = @csvdata[10]  if @csvdata[10].nil?
    raise FreeREGError, "The mother's surname #{@csvdata[11]} contains invalid characters" unless cleanname(11)
    data_record[:mother_surname] = Unicode::upcase(@csvdata[11]) unless @csvdata[11].nil?
    data_record[:mother_surname] = @csvdata[11]  if @csvdata[11].nil?
    raise FreeREGError, "The abode #{@csvdata[12]} contains invalid characters" unless cleantext(12)
    data_record[:person_abode] = @csvdata[12]
    raise FreeREGError, "The father's occupation #{@csvdata[13]} contains invalid characters" unless cleantext(13)
    data_record[:father_occupation] = @csvdata[13]
    raise FreeREGError, "The notes #{@csvdata[14]} contains invalid characters" unless cleantext(14)
    data_record[:notes] = @csvdata[14]
    number = @@list_of_registers[@@place_register_key].fetch(:records)
    number = number + 1
    @@list_of_registers[@@place_register_key].store(:records,number)
    
    if @@header[:lds] == "yes" then
      data_record[:film] = @csvdata[15]
      data_record[:film_number] = @csvdata[16]
    end
     @@data_hold[@@place_register_key].store(number,data_record) 
   
  end
  #process the marriage data columns

  def self.process_marriage_data_records(n)
    data_record = Hash.new
    data_record[:line_id] = @@userid + "." + File.basename(@@filename.upcase) + "." + n.to_s
    data_record[:file_line_number] = n
    raise FreeREGError, "Register Entry Number #{@csvdata[3]} contains non numeric characters" unless cleantext(3)
    data_record[:register_entry_nuber] = @csvdata[3]
    raise FreeREGError, "The date of the marriage #{@csvdata[4]} is in the wrong format" unless datevalsplit(@csvdata[4],"Marriage")
    data_record[:marriage_date_split] = @splityear
    data_record[:marriage_date] = @csvdata[4]
    raise FreeREGError, "The groom's forename #{@csvdata[5]} contains invalid characters" unless cleanname(5)
    data_record[:groom_forename] = @csvdata[5]
    raise FreeREGError, "The groom's surname #{@csvdata[6]} contains invalid characters" unless cleanname(6)
    data_record[:groom_surname] = Unicode::upcase(@csvdata[6]) unless @csvdata[6].nil?
    data_record[:groom_surname] = @csvdata[6] if @csvdata[6].nil?
    raise FreeREGError, "The groom's age #{@csvdata[7]} contains invalid characters" unless cleanage(7)
    data_record[:groom_age] = @csvdata[7]
    raise FreeREGError, "The groom's parish #{@csvdata[8]} contains invalid characters" unless cleantext(8)
    data_record[:groom_parish] = @csvdata[8]
#    raise FreeREGError, "The groom's condition #{@csvdata[9]} contains unknown condition #{@csvdata[9]} in line #{n}" unless cleancondition(9)
    raise FreeREGError, "The groom's condition #{@csvdata[9]} contains unknown condition #{@csvdata[9]}" unless cleantext(9)
    data_record[:groom_condition] = @csvdata[9]
    raise FreeREGError, "The groom's occupation #{@csvdata[10]} contains invalid characters" unless cleantext(10)
    data_record[:groom_occupation] = @csvdata[10]
    raise FreeREGError, "The groom's abode #{@csvdata[11]} contains invalid characters #{@csvdata[11]}" unless cleantext(11)
    data_record[:groom_abode] = @csvdata[11]
    raise FreeREGError, "The bride's forename #{@csvdata[12]} contains invalid characters" unless cleanname(12)
    data_record[:bride_forename] = @csvdata[12]
    raise FreeREGError, "The bride's surname #{@csvdata[13]} contains invalid characters" unless cleanname(13)
    data_record[:bride_surname] = Unicode::upcase(@csvdata[13]) unless @csvdata[13].nil?
    data_record[:bride_surname] = @csvdata[13] if @csvdata[13].nil?
    raise FreeREGError, "The bride's age #{@csvdata[14]} field is invalid" unless cleanage(14)
    data_record[:bride_age] = @csvdata[14]
    raise FreeREGError, "The bride's parish #{@csvdata[15]} contains invalid characters" unless cleantext(15)
    data_record[:bride_parish] = @csvdata[15]
#    raise FreeREGError, "The bride's condition #{@csvdata[16]} contains unknown condition in line #{n}" unless cleancondition(16)
    raise FreeREGError, "The groom's condition #{@csvdata[9]} contains unknown condition #{@csvdata[9]}" unless cleantext(9)
    data_record[:bride_condition] = @csvdata[16]
    raise FreeREGError, "The bride's occupation #{@csvdata[17]} contains invalid characters" unless cleantext(17)
    data_record[:bride_occupation] = @csvdata[17]
    raise FreeREGError, "The bride's abode #{@csvdata[18]} contains invalid characters" unless cleantext(18)
    data_record[:bride_abode] = @csvdata[18]
    raise FreeREGError, "The groom's fathers forename #{@csvdata[19]} contains invalid characters" unless cleanname(19)
    data_record[:groom_father_forename] = @csvdata[19]
    raise FreeREGError, "The groom's fathers surname #{@csvdata[20]} contains invalid characters" unless cleanname(20)
    data_record[:groom_father_surname] = Unicode::upcase(@csvdata[20]) unless @csvdata[20].nil?
    data_record[:groom_father_surname] = @csvdata[20] if @csvdata[20].nil?
    raise FreeREGError, "The groom's father's occupation #{@csvdata[21]} contains invalid characters" unless cleantext(21)
    data_record[:groom_father_occupation] = @csvdata[21]
    raise FreeREGError, "The bride's fathers forename #{@csvdata[22]} contains invalid characters" unless cleanname(22)
    data_record[:bride_father_forename] = @csvdata[22]
    raise FreeREGError, "The bride's fathers surname #{@csvdata[23]} contains invalid characters" unless cleanname(23)
    data_record[:bride_father_surname] = Unicode::upcase(@csvdata[23]) unless @csvdata[23].nil?
    data_record[:bride_father_surname] = @csvdata[23] if @csvdata[23].nil?
    raise FreeREGError, "The bride's father's occupation #{@csvdata[24]} contains invalid characters" unless cleantext(24)
    data_record[:bride_father_occupation] = @csvdata[24]
    raise FreeREGError, "The first witness forename #{@csvdata[25]} contains invalid characters" unless cleanname(25)
    data_record[:witness1_forename] = @csvdata[25]
    raise FreeREGError, "The first witness's surname #{@csvdata[26]} contains invalid characters" unless cleanname(26)
    data_record[:witness1_surname] = Unicode::upcase(@csvdata[26]) unless @csvdata[26].nil?
    data_record[:witness1_surname] = @csvdata[26] if @csvdata[26].nil?
    raise FreeREGError, "The second witness forename #{@csvdata[27]} contains invalid characters" unless cleanname(27)
    data_record[:witness2_forename] = @csvdata[27]
    raise FreeREGError, "The second witness's surname #{@csvdata[28]} contains invalid characters" unless cleanname(28)
    data_record[:witness2_surname] = Unicode::upcase(@csvdata[28]) unless @csvdata[28].nil?
    data_record[:witness2_surname] = @csvdata[28] if @csvdata[28].nil?
    raise FreeREGError, "The notes #{@csvdata[29]} contains invalid characters" unless cleantext(29)
    data_record[:notes] = @csvdata[29]
     data_record[:notes] = @csvdata[14]
    number = @@list_of_registers[@@place_register_key].fetch(:records)
    number = number + 1
    @@list_of_registers[@@place_register_key].store(:records,number)
            
    if @@header[:lds] == "yes"  then
      data_record[:film] = @csvdata[30]
      data_record[:film_number] = @csvdata[31]
    end
     @@data_hold[@@place_register_key].store(number,data_record) 
  end

  #process the burial data columns
  def self.process_burial_data_records(n)
    data_record = Hash.new
    data_record[:line_id] = @@userid + "." + File.basename(@@filename.upcase) + "." + n.to_s
    data_record[:file_line_number] = n
    raise FreeREGError, "Register Entry Number #{@csvdata[3]} contains non numeric characters" unless cleantext(3)
    data_record[:register_entry_nuber] = @csvdata[3]
    raise FreeREGError, "The date of the burial #{@csvdata[4]} is in the wrong format" unless datevalsplit(@csvdata[4],"Burial")
    data_record[:burial_date_split] = @splityear
    data_record[:burial_date] = @csvdata[4]
    raise FreeREGError, "The person's forename #{@csvdata[5]} contains invalid characters" unless cleanname(5)
    data_record[:burial_person_forename] = @csvdata[5]
    raise FreeREGError, "The relationship #{@csvdata[6]} contains invalid characters" unless cleanname(6)
    data_record[:relationship] = @csvdata[6]
    raise FreeREGError, "The male relative's forename #{@csvdata[7]} contains invalid characters" unless cleanname(7)
    data_record[:male_relative_forename] = @csvdata[7]
    raise FreeREGError, "The female relative's forename #{@csvdata[8]} contains invalid characters" unless cleanname(8)
    data_record[:female_relative_forename] = @csvdata[8]
    raise FreeREGError, "The relative's surname #{@csvdata[9]} contains invalid characters" unless cleanname(9)
    data_record[:relative_surname] = Unicode::upcase(@csvdata[9]) unless @csvdata[9].nil?
    data_record[:relative_surname] = @csvdata[9] if @csvdata[9].nil?
    raise FreeREGError, "The person's surname #{@csvdata[10]} contains invalid characters" unless cleanname(10)
    data_record[:burial_person_surname] = Unicode::upcase(@csvdata[10])  unless @csvdata[10].nil?
    data_record[:burial_person_surname] = @csvdata[10]  if @csvdata[10].nil?
    raise FreeREGError, "The person's age #{@csvdata[11]} field is invalid" unless cleanage(11)
    data_record[:person_age] = @csvdata[11]
    raise FreeREGError, "The person's abode #{@csvdata[12]} contains invalid characters" unless cleantext(12)
    data_record[:burial_person_abode] = @csvdata[12]
    raise FreeREGError, "The notes #{@csvdata[13]} contains invalid characters" unless cleantext(13)
    data_record[:notes] = @csvdata[13]
 
     data_record[:notes] = @csvdata[14]
    number = @@list_of_registers[@@place_register_key].fetch(:records)
    number = number + 1
    @@list_of_registers[@@place_register_key].store(:records,number)
            
    if @@header[:lds] == "yes"  then
      data_record[:film] = @csvdata[14]
      data_record[:film_number] = @csvdata[15]
    end
    @@data_hold[@@place_register_key].store(number,data_record) 
  end

  def self.create_db_record_for_entry(data_record)
    # TODO: bring data_record hash keys in line with those in Freereg1CsvEntry

    entry = Freereg1CsvEntry.new(data_record)
    entry.freereg1_csv_file = @freereg1_csv_file
    entry.save
    entry.transform_search_record if  @@create_search_records == true
    entry
  end

 
  def self.delete_all
    Freereg1CsvEntry.delete_all
    Freereg1CsvFile.delete_all
    SearchRecord.delete_freereg1_csv_entries
  end

  def self.process_register_headers
    @@list_of_registers.each do |place_key,head_value|
      @@header.merge!(head_value)
      #puts "header #{head} \n"
      @freereg1_csv_file = Freereg1CsvFile.new(@@header)
      @freereg1_csv_file.update_register
      #write the data records for this place/church
      @@data_hold[place_key].each do |datakey,datarecord|
        
        datarecord[:county] = head_value[:county]
        datarecord[:place] = head_value[:place]
        datarecord[:church_name] = head_value[:church_name]
        datarecord[:register_type] = head_value[:register_type]
        #puts "Data record #{datakey} \n #{datarecord} \n"
        create_db_record_for_entry(datarecord)
      end
    end
  end

  def self.process_the_data
                  
     @@number_of_line = 0
     @@number_of_error_messages = 0
     @line_type = 'hold'
     @@header_line = 1
       n = 1
          loop do
            begin
                @line_type = get_line_of_data
                if @line_type == 'Header'  
                  case 
                    when @@header_line == 1 
                      process_header_line_one
                      @@header_line = @@header_line + 1      
                    when @@header_line == 2 
                      process_header_line_two
                      @@header_line = @@header_line + 1
                    when @@header_line == 3 
                      process_header_line_threee
                      @@header_line = @@header_line + 1
                    when @@header_line == 4 
                      process_header_line_four
                      @@header_line = @@header_line + 1
                    when @@header_line == 5 
                      process_header_line_five
                      @@header_line = @@header_line + 1
                    else 
                     raise FreeREGError,  "Unknown header " 
                  end #end of case

                else
                   
                  type = @@header[:record_type]
                  process_register_location(n)
                  case type
                    when RecordType::BAPTISM then process_baptism_data_records(n)
                    when RecordType::BURIAL then process_burial_data_records(n)                      
                    when RecordType::MARRIAGE then process_marriage_data_records(n)
                  end# end of case
                  n =  n + 1
                 
                end #end of line type loop
                       
              @@number_of_line = @@number_of_line + 1

                #  break if n == 10

                #rescue the freereg data errors and continue processing the file
        
                rescue FreeREGError => free
          
                   @@user_message_file = File.new(@@user_file_for_warning_messages, "w")  if @@number_of_error_messages == 0
                   @@number_of_error_messages = @@number_of_error_messages + 1
                   line_number = @@number_of_line + 1
                    puts "#{@@userid} #{@@filename}" + free.message + " at line #{line_number}"
                    @@message_file.puts "#{@@userid}\t#{@@filename}" + free.message + " at line #{line_number}"
                    @@user_message_file.puts free.message + " at line #{line_number}"
                    @@number_of_line = @@number_of_line + 1
                     #    n = n - 1 unless n == 0
                    break if (free.message == "Empty file" || free.message == "Invalid Character Set" || @line_type == 'Header'  )
                    retry  
                rescue FreeREGEnd => free
                   n = n - 1
                   puts "#@@userid #{@@filename} processed  #{n} data lines correctly with #{@@number_of_error_messages} error messages" 
                   @@message_file.puts "#@@userid\t#{@@filename}\tprocessed  #{n} data lines correctly with #{@@number_of_error_messages} error messages"
                   @@header[:error] = @@number_of_error_messages

                   process_register_headers
                   break
                rescue  => e 
                  @@user_message_file = File.new(@@user_file_for_warning_messages, "w") unless File.exists?(@@user_file_for_warning_messages)
                  @@user_message_file.puts e.message  
                  @@user_message_file.puts "Something seriously wrong with your file during processing please contact your coordinator"
                   puts e.message
                   puts e.backtrace
                   @@message_file.puts "#{@@userid}\t#{@@filename} line #{n} crashed the processor\n"  
                   @@message_file.puts e.message  
                   @@message_file.puts e.backtrace.inspect 
                   break 

                end#end of begin
               
            end #end of loop
    return n       
 end #end of method


 def self.slurp_the_csv_file(filename)
               
    begin
          #we slurp in the full csv file
          @@array_of_data_lines = CSV.read(filename, external_encoding:@@charset , internal_encoding:"UTF-8")

          success = true
          #we rescue when for some reason the slurp barfs
          rescue => e 
                    @@user_message_file = File.new(@@user_file_for_warning_messages, "w") unless File.exists?(@@user_file_for_warning_messages)
                   @@user_message_file.puts e.message  
                   @@user_message_file.puts "Something seriously wrong with your file; it was not processed please contact your coordinator"
                   puts e.message
                   @@message_file.puts "#{@@userid}\t#{@@filename} *barfed the system*************"  
                   @@message_file.puts e.message  
                   @@message_file.puts e.backtrace.inspect 
                   success = false
                  
          else
            raise FreeREGError,  "Empty file" if @@array_of_data_lines.nil?
          ensure
          #we ensure that processing keeps going by dropping outthrough the bottom     
    end #begin end
   return success
  end #method end

  def self.check_for_replace(filename)
                 
    #check to see if we should process the file
    #is it aleady there?
    check_for_file = Freereg1CsvFile.where({ :file_name => @@header[:file_name], 
                                :userid => @@header[:userid]}).first
    if check_for_file.nil?
    #if file not there then need to create
      return true
    else
      #file is in the database
      if check_for_file.locked == true then
        #do not process if coordinator has locked
        p "#{@@header[:file_name]} has been locked by the coordinator"
         @@user_message_file = File.new(@@user_file_for_warning_messages, "w") unless File.exists?(@@user_file_for_warning_messages)
         @@user_message_file.puts "#{@@userid} #{@@header[:file_name]} has been locked by the coordinator"
         @@message_file.puts "#{@@userid}\t#{@@header[:file_name]} has been locked by the coordinator"
        return false
      end
      if @@header[:digest] == check_for_file.digest then
        #file in database is same or more recent than we we are attempting to reload so do not process
              p  "#{@@userid} #{@@header[:file_name]} has not changed since last build"
              @@message_file.puts "#{@@userid}\t#{@@header[:file_name]} has not changed since last build"
          return false
      end
      
      if (@@uploaded_date.strftime("%s") > check_for_file.uploaded_date.strftime("%s")) 
       
           #file is in the database but we have a more recent copy uploaded
            #so delete what is there and process the new file
            Freereg1CsvFile.delete_file(check_for_file._id)
            
            return true
      else
             #file in database is same or more recent than we we are attempting to reload so do not process
              p  "#{@@userid} #{@@header[:file_name]} has not changed since last build"
             
              @@message_file.puts "#{@@userid}\t#{@@header[:file_name]} has not changed since last build"
              
           return false
       end #date check end
      
    end #check_for_file loop end

  end #method end

  def self.setup_for_new_file(filename)
    # turn off domain checks -- some of these email accounts may no longer work and that's okay
    #initializes variables
    #gets information on the file to be processed
                  
          @@header = Hash.new
          @csvdata = Array.new
          @code_sets = Encoding.name_list
          @@list_of_registers = Hash.new()
          @@data_hold = Hash.new
          @data_record = Hash.new
          @@array_of_data_lines = Array.new {Array.new}
          @@charset = "iso-8859-1"
          @@file = filename
          standalone_filename = File.basename(filename)
          @@filename = standalone_filename
          full_dirname = File.dirname(filename)
          parent_dirname = File.dirname(full_dirname)
          user_dirname = full_dirname.sub(parent_dirname, '').gsub(File::SEPARATOR, '')
          @@userid = user_dirname
          print "#{user_dirname} #{standalone_filename}\n"
          @@message_file.puts "#{user_dirname}\t#{standalone_filename}\n"
          @@header[:digest] = Digest::MD5.file(filename).hexdigest 
          #delete any user log file for errors we put it in the same directory as the csv file came from    
          @@user_file_for_warning_messages = full_dirname + '/' + standalone_filename + ".log"
          File.delete(@@user_file_for_warning_messages) if File.exists?(@@user_file_for_warning_messages)
          @@header[:file_name] = standalone_filename #do not capitalize filenames
          @@header[:userid] = user_dirname
          @@uploaded_date = File.mtime(filename)
          @@header[:uploaded_date] = @@uploaded_date 
    
  end

  def self.process(recreate,create_search_records,base_directory,range)
    #this is the basic processing
    
     #set up message files 
     EmailVeracity::Config[:skip_lookup]=true
     file_for_warning_messages = "log/freereg_messages.log"
     FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
     @@message_file = File.new(file_for_warning_messages, "a")
     p "Started a build with options of #{recreate} with #{create_search_records} a base directory at #{base_directory} and a file #{range}"
     @@message_file.puts "Started a build with options of #{recreate} with #{create_search_records} a base directory at #{base_directory} and a file #{range}"
     @@create_search_records = false
     @@create_search_records = true if create_search_records == 'create_search_records'
     #set up to determine files to be processed
     filenames = GetFiles.get_all_of_the_filenames(base_directory,range)
      
      @@message_file.puts "#{filenames.length}\t files selected for processing\n"
       time_start = Time.now
       nn = 2
       #now we cycle through the files
      filenames.each do |filename|
         time_file_start = Time.now
         setup_for_new_file(filename)

         process = true 
         process = check_for_replace(filename) unless recreate == "recreate"

         success = slurp_the_csv_file(filename) if process == true

        n = process_the_data if success == true  && process == true
        nn = nn + n unless n.nil?

     end #filename loop end 

     time = (((Time.now  - time_start )/(nn-1))*1000)
     p "Created  #{nn} entries at an average time of #{time}ms per record\n" 
     @@message_file.puts  "Created  #{nn} entries at an average time of #{time}ms per record\n"  
  end #method end
 
end #class end

#set the FreeREG error conditions
class FreeREGError < StandardError
end

class FreeREGEnd < StandardError
end

#class FreeREGError < StandardError
#end
# 
# require 'pry'


