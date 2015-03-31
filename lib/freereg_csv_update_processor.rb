class FreeregCsvUpdateProcessor
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
  require "#{Rails.root}/app/models/userid_detail"
  require 'freereg_validations'
  CONTAINS_PERIOD = /\./
  DATEMAX = 2020
  DATEMIN = 1530
  HEADER_FLAG = /\A\#\z/
  ST_PERIOD = /\A[Ss][Tt]\z/

  VALID_CHAR = /[^a-zA-Z\d\!\+\=\_\&\?\*\)\(\]\[\}\{\'\" \.\,\;\/\:\r\n\@\$\%\^\-\#]/

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
  VALID_DATE = /\A\d{1,2}[\s+\/\-][A-Za-z\d]{0,3}[\s+\/\-]\d{2,4}\z/
  VALID_NUMERIC_MONTH = /\A\d{1,2}\z/
  VALID_CCC_CODE = /\A[CcSs]{3,6}\z/
  VALID_CREDIT_CODE = ["CREDIT", "Credit", "credit"]
  VALID_NAME = /[^A-Za-z\)\(\]\[\}\{\?\*\'\"\ \.\,\;\:\_]/
  VALID_TEXT = /[^A-Za-z\)\(\]\[\}\{\?\*\'\"\ \.\,\;\:\_\!\+\=]/

  VALID_MALE_SEX = ["M","M." ,"SON","MALE","MM","SON OF"]
  UNCERTAIN_MALE_SEX = ["M?","SON?","[M]" ,"MF"]
  UNCERTAIN_FEMALE_SEX = ["F?", "DAU?"]
  UNCERTAIN_SEX = ["?", "-", "*","_","??"]
  VALID_MONTH = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP","SEPT", "OCT", "NOV", "DEC", "*","JANUARY","FEBRUARY","MARCH","APRIL","MAY","JUNE","JULY","AUGUST","SEPTEMBER","OCTOBER","NOVEMBER","DECEMBER"]
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
  WORD_START_BRACKET =  /\A\(/
  DATE_SPLITS = {
    " " => /\s/,
    "-" => /\-/,
  "/" => /\\/}
  CAPITALIZATION_WORD_EXCEPTIONS = [
    "a", "an", "and", "at", "but", "by", "cum", "de", "en" ,"for", "has", "in", "la", "le", "near", "next", "nor", "nr", "or", "on", "of", "so",
  "the", "to", "under","von", "with", "yet", "y"]


  attr_accessor :freereg1_csv_file


  # validate the modern date of creation or modification
  def self.datevalmod(m)
    return true if @csvdata[m].nil? || @csvdata[m].empty?
    if  @csvdata[m] =~ VALID_DATE
      DATE_SPLITS.each_pair do |date_splitter, date_split|
        date_parts = @csvdata[m].split(date_split)
        unless date_parts[1].nil?
          return true if  VALID_MONTH.include?(date_parts[1].upcase) || date_parts[1] =~ VALID_NUMERIC_MONTH
        end
      end
    end
    return false
  end

  #calculate the minimum and maximum dates in the file; also populate the decadal content table starting at 1530
  def self.datestat(x)
    xx = x.to_i
    daterange = Array.new
    datemax = @@list_of_registers[@@place_register_key].fetch(:datemax)
    datemin = @@list_of_registers[@@place_register_key].fetch(:datemin)
    daterange = @@list_of_registers[@@place_register_key].fetch(:daterange)
    datemax = xx if xx > datemax && xx < DATEMAX
    datemin = xx if xx < datemin
    bin = (xx-DATEMIN)/10
      daterange[bin] = daterange[bin] + 1 unless xx > DATEMAX || xx < DATEMIN #avoid going beyond the range
    #   p "data range #{datemax} #{datemin} #{bin} #{daterange}"
      @@list_of_registers[@@place_register_key].store(:datemax,datemax)
      @@list_of_registers[@@place_register_key].store(:datemin,datemin)
      @@list_of_registers[@@place_register_key].store(:daterange,daterange)
  end

  #validate dates in the record and allow for the split date format 1567/8 and 1567/68 creates a base year and a split year eg /8



    #clean up the sex field
    def self.cleansex(field)
      if field.nil? || field.empty?
        field = nil
      else
        case
        when VALID_MALE_SEX.include?(field.upcase)
          field = "M"

        when UNCERTAIN_MALE_SEX.include?(field.upcase)
          field = "M?"

        when VALID_FEMALE_SEX.include?(field.upcase)
          field = "F"

        when UNCERTAIN_FEMALE_SEX.include?(field.upcase)
          field = "F?"

        when UNCERTAIN_SEX.include?(field.upcase)
          field = "?"
        else
          field
        end #end case
      end #end if
      field
    end #end method




    def self.mycapitalize(word,num,type_of_name)
      word = CHURCH_WORD_EXPANSIONS[word] if CHURCH_WORD_EXPANSIONS.has_key?(word) && type_of_name == "Church"
      word = COMMON_WORD_EXPANSIONS[word] if COMMON_WORD_EXPANSIONS.has_key?(word)
      word = Unicode::downcase(word)
      word = Unicode::capitalize(word) unless CAPITALIZATION_WORD_EXCEPTIONS.include?(word)
      if word =~ WORD_START_BRACKET
        #word is in a ()
        word = Unicode::capitalize(word.gsub(/\(?/, '')).insert(0, "(")
      end
      word = Unicode::capitalize(word) if num == 0
      return word
    end

    def self.validregister(m,type_of_name)
      #cleans up Church and Place names
      @register = nil
      @register_type = nil
      return true if m.nil? || m.empty?
      register_words = m.split(" ")
      n = register_words.length

      #register_words[-1] = register_words[-1].gsub(/\(?\)?/, '')

      if (type_of_name == "Church" ) then
        if n > 1
          if register_words[-1] =~ VALID_REGISTER_TYPES then
            # extract a Register Type field from the church field
            register_words[-1] = register_words[-1].gsub(/\(?\)?'?"?[Ss]?/, '')
            register_words[-1] = Unicode::upcase(register_words[-1])

            if VALID_REGISTER_TYPE.include?(register_words[-1])
              # check that it is a valid code
              @register_type = register_words[-1]
              n = n - 1
              @register_type = "DW" if @register_type == "DT"
              @register_type = "PH" if @register_type == "PT"
            else
              @register_type = ""
              return true
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
        raise FreeREGError,  "Header_Error,First line of file does not start with +INFO it has #{@csvdata[0]}" unless ((@csvdata[0] == "+INFO") || (@csvdata[0] == "#NAME?"))
        # BWB: temporarily commenting out to test db interface
        #   address = EmailVeracity::Address.new(@csvdata[1])
        #   raise FreeREGError,  "Invalid email address #{@csvdata[1]} in first line of header" unless address.valid?
        @@header [:transcriber_email] = @csvdata[1]
        new_email  = UseridDetail.where(:userid =>  @@header [:userid] ).first
        new_email = new_email.email_address unless new_email.nil?
        @@header [:transcriber_email] = new_email unless new_email.nil?
        raise FreeREGError,  "Header_Error,Invalid file type #{@csvdata[4]} in first line of header" unless VALID_RECORD_TYPE.include?(@csvdata[4].gsub(/\s+/, ' ').strip.upcase)
        # canonicalize record type
        scrubbed_record_type = Unicode::upcase(@csvdata[4]).gsub(/\s/, '')
        @@header [:record_type] =  RECORD_TYPE_TRANSLATION[scrubbed_record_type]
        #raise FreeREGError, "Header_Error,Invalid characterset #{@csvdata[5]} in the first header line" unless charvalid(@csvdata[5])
        #@@header [:characterset] = @csvdata[5]
      end

      #process the header line 2
      # eg #,CCCC,David Newbury,Derbyshire,dbysmalbur.CSV,02-Mar-05,,,,,,,
      def self.process_header_line_two
        @csvdata = @csvdata.compact
        @number_of_fields = @csvdata.length
        raise FreeREGError, "Header_Error,The second header line is completely empty; please check the file for blank lines" if @number_of_fields == 0
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
                raise FreeREGError, "Header_Error,I did not know enough about your data format to extract transciber information at header line 2"

        end

      end

            def self.process_header_line_two_block
              raise FreeREGError, "Header_Error,The transcriber's name #{@csvdata[2]} can only contain alphabetic and space characters in the second header line" unless FreeregValidations.cleantext(@csvdata[2])
              @@header [:transcriber_name] = @csvdata[2]
              raise FreeREGError, "Header_Error,The syndicate can only contain alphabetic and space characters in the second header line" unless FreeregValidations.cleantext(@csvdata[3])
              @@header [:transcriber_syndicate] = @csvdata[3]
              @csvdata[5] = '01 Jan 1998' unless datevalmod(5)
              @@header [:transcription_date] = @csvdata[5]
              userid = UseridDetail.where(:userid =>  @@header [:userid] ).first

              @@header [:transcriber_syndicate] = userid.syndicate unless userid.nil?

            end

            #process the @@headerer line 3
            # eg #,Credit,Libby,email address,,,,,,
            def self.process_header_line_threee
              @csvdata = @csvdata.compact
              @number_of_fields = @csvdata.length
              raise FreeREGError, "Header_Error,The third header line is completely empty; please check the file for blank lines" if @number_of_fields == 0

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
                raise FreeREGError, "Header_Error,I did not know enough about your data format to extract Credit Information at header line 3"
              end

            end

            def self.process_header_line_three_block
              raise FreeREGError, "Header_Error,The credit person name #{@csvdata[2]} can only contain alphabetic and space characters in the third header line" unless FreeregValidations.cleantext(@csvdata[2])
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
              raise FreeREGError, "Header_Error,The forth header line is completely empty; please check the file for blank lines" if @number_of_fields == 0
              case
              when (@number_of_fields == 4 && @csvdata[0] =~ HEADER_FLAG && datevalmod(1))
                #standard format
                @@header [:modification_date] = @csvdata[1]
                @@header [:first_comment] = @csvdata[2]
                @@header [:second_comment] = @csvdata[3]
              when (@number_of_fields == 1 && @csvdata[0] =~ HEADER_FLAG)
                # an empty line follows the #
              when (@number_of_fields == 1 && !(@csvdata[0] =~ HEADER_FLAG))
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
                  raise FreeREGError, "Header_Error,I did not know enough about your data format to extract notes Information at header line 4"

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
                  raise FreeREGError, "Header_Error,I did not know enough about your data format to extract notes Information at header line 4"

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
                raise FreeREGError, "Header_Error,I did not know enough about your data format to extract notes Information at header line 4"

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
              #this code is needed to permit multiple places and churches in a single batch in any order
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
              @@list_of_registers[place_register_key].store(:record_type,data_record[:record_type])
              @@list_of_registers[place_register_key].store(:alternate_register_name,data_record[:alternate_register_name])
              @@list_of_registers[place_register_key].store(:records,@number_of_records)
              @@list_of_registers[place_register_key].store(:datemax,@@datemax)
              @@list_of_registers[place_register_key].store(:datemin,@@datemin)
              @@list_of_registers[place_register_key].store(:daterange,@@daterange)

            end

            def self.process_register_location(n)
              data_record = Hash.new
              raise FreeREGError, "Empty data line"  if @csvdata[0].nil?
              raise FreeREGError,"The county code #{ @csvdata[0]} is invalid or you have a blank record line " unless ChapmanCode::values.include?(@csvdata[0])

              # do we validate the Place field?
              raise FreeREGError, "Place field #{@csvdata[1]} is invalid" unless validregister(@csvdata[1],"Place")
              raise FreeREGError, "The Place #{@csvdata[1]} is not in the database" unless Place.where(:place_name => @csvdata[1]).exists
              data_record[:place] = @register
              # do we validate the register field
              raise FreeREGError, "Church field #{@csvdata[2]} is invalid in some way" unless validregister(@csvdata[2],"Church")
              data_record[:county] = @csvdata[0]
              data_record[:church_name] = @register
              data_record[:register_type] = @register_type
              data_record[:record_type] = @@header[:record_type]
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
              data_record[:register_entry_number] = @csvdata[3]
              data_record[:birth_date] = @csvdata[4]
              data_record[:baptism_date] = @csvdata[5]
              data_record[:year] = FreeregValidations.year_extract(@csvdata[5])
              datestat(data_record[:year]) unless data_record[:year].nil?
              data_record[:person_forename] = @csvdata[6]
              data_record[:person_sex] = cleansex(@csvdata[7])
              data_record[:father_forename] = @csvdata[8]
              data_record[:mother_forename] = @csvdata[9]
              data_record[:father_surname] = Unicode::upcase(@csvdata[10]) unless @csvdata[10].nil?
              data_record[:father_surname] = @csvdata[10]  if @csvdata[10].nil?
              data_record[:mother_surname] = Unicode::upcase(@csvdata[11]) unless @csvdata[11].nil?
              data_record[:mother_surname] = @csvdata[11]  if @csvdata[11].nil?
              data_record[:person_abode] = @csvdata[12]
              data_record[:father_occupation] = @csvdata[13]
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

              data_record[:register_entry_number] = @csvdata[3]

              data_record[:marriage_date] = @csvdata[4]
              data_record[:year] = FreeregValidations.year_extract(@csvdata[4])
              datestat(data_record[:year]) unless data_record[:year].nil?
              data_record[:groom_forename] = @csvdata[5]
              data_record[:groom_surname] = Unicode::upcase(@csvdata[6]) unless @csvdata[6].nil?
              data_record[:groom_surname] = @csvdata[6]  if @csvdata[6].nil?
              data_record[:groom_age] = @csvdata[7]
              data_record[:groom_parish] = @csvdata[8]
              #    raise FreeREGError, "The groom's condition #{@csvdata[9]} contains unknown condition #{@csvdata[9]} in line #{n}" unless cleancondition(9)
              data_record[:groom_condition] = @csvdata[9]
              data_record[:groom_occupation] = @csvdata[10]
              data_record[:groom_abode] = @csvdata[11]
              data_record[:bride_forename] = @csvdata[12]
              data_record[:bride_surname] = Unicode::upcase(@csvdata[13]) unless @csvdata[13].nil?
              data_record[:bride_surname] = @csvdata[13] if @csvdata[13].nil?
              data_record[:bride_age] = @csvdata[14]
              data_record[:bride_parish] = @csvdata[15]
              #    raise FreeREGError, "The bride's condition #{@csvdata[16]} contains unknown condition in line #{n}" unless cleancondition(16)
              data_record[:bride_condition] = @csvdata[16]
              data_record[:bride_occupation] = @csvdata[17]
              data_record[:bride_abode] = @csvdata[18]
              data_record[:groom_father_forename] = @csvdata[19]
              data_record[:groom_father_surname] = Unicode::upcase(@csvdata[20]) unless @csvdata[20].nil?
              data_record[:groom_father_surname] = @csvdata[20] if @csvdata[20].nil?
              data_record[:groom_father_occupation] = @csvdata[21]
              data_record[:bride_father_forename] = @csvdata[22]
              data_record[:bride_father_surname] = Unicode::upcase(@csvdata[23]) unless @csvdata[23].nil?
              data_record[:bride_father_surname] = @csvdata[23] if @csvdata[23].nil?
              data_record[:bride_father_occupation] = @csvdata[24]
              data_record[:witness1_forename] = @csvdata[25]
              data_record[:witness1_surname] = Unicode::upcase(@csvdata[26]) unless @csvdata[26].nil?
              data_record[:witness1_surname] = @csvdata[26] if @csvdata[26].nil?
              data_record[:witness2_forename] = @csvdata[27]
              data_record[:witness2_surname] = Unicode::upcase(@csvdata[28]) unless @csvdata[28].nil?
              data_record[:witness2_surname] = @csvdata[28] if @csvdata[28].nil?
              data_record[:notes] = @csvdata[29]

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
              data_record[:register_entry_number] = @csvdata[3]
              data_record[:burial_date] = @csvdata[4]
              data_record[:year] = FreeregValidations.year_extract(@csvdata[4])
              datestat(data_record[:year]) unless data_record[:year].nil?
              data_record[:burial_person_forename] = @csvdata[5]
              data_record[:relationship] = @csvdata[6]
              data_record[:male_relative_forename] = @csvdata[7]
              data_record[:female_relative_forename] = @csvdata[8]
              data_record[:relative_surname] = Unicode::upcase(@csvdata[9]) unless @csvdata[9].nil?
              data_record[:relative_surname] = @csvdata[9] if @csvdata[9].nil?
              data_record[:burial_person_surname] = Unicode::upcase(@csvdata[10])  unless @csvdata[10].nil?
              data_record[:burial_person_surname] = @csvdata[10]  if @csvdata[10].nil?
              data_record[:person_age] = @csvdata[11]
              data_record[:burial_person_abode] = @csvdata[12]
              data_record[:notes] = @csvdata[13]


              number = @@list_of_registers[@@place_register_key].fetch(:records)
              number = number + 1
              @@list_of_registers[@@place_register_key].store(:records,number)

              if @@header[:lds] == "yes"  then
                data_record[:film] = @csvdata[14]
                data_record[:film_number] = @csvdata[15]
              end
              @@data_hold[@@place_register_key].store(number,data_record)
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
                  datarecord[:record_type] = head_value[:record_type]
                  #puts "Data record #{datakey} \n #{datarecord} \n"
                  success = create_db_record_for_entry(datarecord)
                  unless  success.nil?
                    batch_error = BatchError.new(error_type: 'Data_Error', record_number: datarecord[:file_line_number],error_message: success,record_type: @freereg1_csv_file.record_type, data_line: datarecord)
                    batch_error.freereg1_csv_file = @freereg1_csv_file
                    batch_error.save


                    @@number_of_error_messages = @@number_of_error_messages + 1

                  end #end success
                end #end @@data_hold
                unless @@header_error.nil?
                  @@header_error.each do |error_key,error_value|

                    batch_error = BatchError.new(error_type: 'Header_Error', record_number: error_value[:line],error_message: error_value[:error],data_line: error_value[:data])
                    batch_error.freereg1_csv_file = @freereg1_csv_file
                    batch_error.save


                  end #end header errors

                end # #header nil

                @freereg1_csv_file.update_attribute(:error, @@number_of_error_messages)
                @freereg1_csv_file.save
                @@number_of_error_messages = 0
                @@header_error = nil

              end #end @@list


              puts "#@@userid #{@@filename} processed  #{@@header[:records]} data lines "
              @@message_file.puts "#@@userid\t#{@@filename}\tprocessed  #{@@header[:records]} data lines "

            end

            def self.create_db_record_for_entry(data_record)
              # TODO: bring data_record hash keys in line with those in Freereg1CsvEntry

              entry = Freereg1CsvEntry.new(data_record)
              entry.freereg1_csv_file = @freereg1_csv_file
              entry.save
              if entry.errors.any?
                success = entry.errors.messages

              else
                entry.transform_search_record if  @@create_search_records == true
                success = nil
              end
              success
            end

            def self.process_the_data
              #we do this here so that the logfile is only deleted if we actually process the file!
              File.delete(@@user_file_for_warning_messages) if File.exists?(@@user_file_for_warning_messages)

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
                      raise FreeREGError,  "Header_Error,Unknown header "
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
                  unless free.message == "Empty data line" then

                    @@number_of_error_messages = @@number_of_error_messages + 1
                    @csvdata = @@array_of_data_lines[@@number_of_line]
                    puts "#{@@userid} #{@@filename}" + free.message + " at line #{@@number_of_line}"
                    @@message_file.puts "#{@@userid}\t#{@@filename}" + free.message + " at line #{@@number_of_line}"


                    @@header_error[@@number_of_error_messages] = Hash.new
                    @@header_error[@@number_of_error_messages].store(:line,@@number_of_line)
                    @@header_error[@@number_of_error_messages].store(:error,free.message)
                    @@header_error[@@number_of_error_messages].store(:data,@csvdata)
                  end
                  @@number_of_line = @@number_of_line + 1
                  #    n = n - 1 unless n == 0
                  @@header_line = @@header_line + 1 if @line_type == 'Header'
                  break if free.message == "Empty file"
                  retry
                rescue FreeREGEnd => free
                  n = n - 1
                  process_register_headers
                  break
                rescue  => e


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

            def self.recode_windows_1252_to_utf8(string)
              string.gsub(/[\u0080-\u009F]/) {|x| x.getbyte(1).chr.
              force_encoding('Windows-1252').encode('utf-8') }
            end

            def self.slurp_the_csv_file(filename)

              begin
                # normalise line endings
                # get character set
                #first_data_line = CSV.parse_line(xxx, {:row_sep => "\r\n",:skip_blanks => true})

                first_data_line = CSV.parse_line(File.open(filename) {|f| f.readline})
                code_set =  first_data_line[5] if first_data_line[0] == "+INFO"
                #set Characterset default

                code_set = "Windows-1252" if (code_set.nil? || code_set.empty? || code_set == "chset")
                #code_set = code_set.gsub(/\s+/, ' ').strip
                #Deal with the cp437 code which is not in ruby also deal with the macintosh instruction in freereg1
                code_set = "Windows-1252" if (code_set == "cp437" || code_set == "CP437")
                code_set = "macRoman" if (code_set.downcase == "macintosh")
                code_set = code_set.upcase if code_set.length == 5 || code_set.length == 6
                @@message_file.puts "Invalid Character Set detected #{code_set} have assumed Windows-1252" unless Encoding.name_list.include?(code_set)
                code_set = "Windows-1252" unless Encoding.name_list.include?(code_set)
                #if we have valid new character set; use it and change the file encoding
                @@charset = Encoding.find(code_set)
                xxx = File.read(filename, :encoding => @@charset).gsub(/\r?\n/, "\r\n").gsub(/\r\n?/, "\r\n")
                xxx = recode_windows_1252_to_utf8(xxx) if code_set == "Windows-1252"
                #now get all the data
                @@array_of_data_lines = CSV.parse(xxx, {:row_sep => "\r\n",:skip_blanks => true})

                @@header [:characterset] = code_set

                success = true
                #we rescue when for some reason the slurp barfs
              rescue => e

                @@message_file.puts "#{@@userid}\t#{@@filename} *barfed the system*************"
                @@message_file.puts e.message
                @@message_file.puts e.backtrace.inspect
                success = false

              else
                raise FreeREGError,  "System_Error,Empty file" if @@array_of_data_lines.nil?
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
                  if (check_for_file.locked_by_transcriber == 'true' || check_for_file.locked_by_coordinator == 'true') then
                    #do not process if coordinator has locked
                      @@message_file.puts "#{@@userid}\t#{@@header[:file_name]} had been locked by either yourself or the coordinator and is not processed"
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
                      Freereg1CsvFile.delete_file(check_for_file)

                      return true
                    else
                      #file in database is same or more recent than we we are attempting to reload so do not process
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
                  @@list_of_registers = Hash.new()
                  @@header_error = Hash.new()
                  @@system_error = Hash.new()
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
                  @@message_file.puts "#{user_dirname}\t#{standalone_filename}\n"
                  @@header[:digest] = Digest::MD5.file(filename).hexdigest
                  #delete any user log file for errors we put it in the same directory as the csv file came from
                  @@user_file_for_warning_messages = full_dirname + '/' + standalone_filename + ".log"
                  File.delete(@@user_file_for_warning_messages)   if File.exists?(@@user_file_for_warning_messages)
                  @@header[:file_name] = standalone_filename #do not capitalize filenames
                  @@header[:userid] = user_dirname
                  @@uploaded_date = File.mtime(filename)
                  @@header[:uploaded_date] = @@uploaded_date
                end

                def self.process(range,type,delta)
                  #this is the basic processing
                  recreate = 'add'
                  create_search_records = "no" unless type == "search_records"
                  create_search_records = 'create_search_records' if type == "search_records"
                  #set up message files
                  EmailVeracity::Config[:skip_lookup]=true
                  base_directory = Rails.application.config.datafiles
                  change_directory = Rails.application.config.datafiles_changeset
                  delta_directory = Rails.application.config.datafiles_delta
                  file_for_warning_messages = "log/update_freereg_messages"
                  time = Time.new.to_i.to_s
                  file_for_warning_messages = (file_for_warning_messages + "." + time + ".log").to_s
                  @@message_file = File.new(file_for_warning_messages, "w")
                  p "Started a build with options of #{recreate} with #{create_search_records} search_records, a base directory at #{base_directory}, a change directory at #{change_directory} and a file #{range} and a delta #{delta}"
                  @@message_file.puts "Started a build at #{Time.new}with options of #{recreate} with #{create_search_records} search_records, a base directory at #{base_directory}, a change directory at #{change_directory} and a file #{range} and a delta #{delta}"
                  @@create_search_records = false
                  @@create_search_records = true if create_search_records == 'create_search_records'
                  #set up to determine files to be processed
                  filenames = GetFiles.get_all_of_the_filenames(change_directory,range) if delta == 'change'
                  filenames = GetFiles.use_the_delta(change_directory,delta_directory) if delta == 'delta'
                  p "#{filenames.length} files selected for processing"
                  @@message_file.puts "#{filenames.length}\t files selected for processing\n"
                  time_start = Time.now
                  nn = 2
                  #now we cycle through the files
                  filenames.each do |filename|
                    setup_for_new_file(filename)
                    process = true
                    process = check_for_replace(filename) unless recreate == "recreate" 
                    @success = slurp_the_csv_file(filename) if process == true
                    n = process_the_data if @success == true  && process == true
                    if Dir.exists?(File.join(base_directory, @@header[:userid]))
                      FileUtils.cp(filename,File.join(base_directory, @@header[:userid], @@header[:file_name] ),:verbose => true) if @success == true  && process == true
                    else
                      @@message_file.puts "No userid directory for #{@@header[:userid]} to hold #{@@header[:file_name]}"
                    end
                    @@message_file.puts "File not processed due to error in reading the file" if @success == false
                    @success = true
                    nn = nn + n unless n.nil?
                  end #filename loop end

                  time = (((Time.now  - time_start )/(nn-1))*1000)
                  p "Created  #{nn} entries at an average time of #{time}ms per record\n" 
                  @@message_file.puts  "Created  #{nn} entries at an average time of #{time}ms per record at #{Time.new}\n" 
                  @@message_file.close 
                  file = @@message_file
                  UseridDetail.where(person_role: "system_administrator").all.each do |user|
                    UserMailer.update_report_to_freereg_manager(file,user).deliver
                  end
                  at_exit do
                  p "goodbye"
                end
                @success  
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