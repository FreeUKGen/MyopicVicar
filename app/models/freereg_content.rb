class FreeregContent
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short

  require 'chapman_code'

  field :county, type: String#, :required => false
  field :chapman_codes,  type: Array, default: []
  validates_inclusion_of :county, :in => ChapmanCode::values+[nil]
  field :place, type: String
  field :church, type: String
  field :record_type, type: String#, :required => false
  field :place_ids, type: String
  attr_accessor :character
  validates_inclusion_of :record_type, :in => RecordType::ALL_FREEREG_TYPES+[nil]
  validate :county_is_valid

  before_validation :clean_blanks

  ######################################################################## class methods

  class << self

    def calculate_freereg_content
      Register.no_timeout.all.each do |register|
        register.calculate_register_numbers
      end
      Church.no_timeout.all.each do |church|
        church.calculate_church_numbers if church.registers.present?
      end
      Place.no_timeout.all.each do |place|
        place.calculate_place_numbers if place.churches.present?
      end
    end

    def calculate_date_range(individual,my_hash,file)
      keys = ["ba","bu","ma","total"]
      if file == "file"
        p individual.record_type unless keys.include?(individual.record_type)
        individual.record_type = "ba" unless keys.include?(individual.record_type)
        my_hash["total"].each_index do |index|
          my_hash[individual.record_type][index] = my_hash[individual.record_type][index] + individual.daterange[index] if individual.daterange[index].present?
          my_hash["total"][index] = my_hash["total"][index] + individual.daterange[index] if individual.daterange[index].present?
        end
      else
        keys.each do |key|
          my_hash[key].each_index do |index|
            my_hash[key][index] = my_hash[key][index] + individual.daterange[key][index] if individual.daterange[key][index].present?
          end
        end
      end
    end

    def check_how_to_proceed(parameter)
      if parameter.nil?
        proceed = "no option"
      elsif parameter[:place].present? && parameter[:character].present?
        proceed = "dual"
      elsif parameter[:place].present?
        proceed = "place"
      elsif parameter[:character].present?
        proceed = "character"
      else
        proceed = "no option"
      end
    end

    def determine_if_selection_needed(chapman,alphabet)
      number = 0
      if alphabet.blank?
        county = County.chapman_code(chapman).first
        number = county.total_records.to_i
        number = (number/FreeregOptionsConstants::RECORDS_PER_RANGE).to_i
        number = FreeregOptionsConstants::ALPHABETS.length - 1 if number >= FreeregOptionsConstants::ALPHABETS.length
      else
        number = alphabet
      end
      number
    end

    def get_header_information(chapman)
      page = Refinery::CountyPages::CountyPage.where(chapman_code: chapman).first
      page
    end

    def get_decades(files)
      decade = { }
      max = 1
      files.each_pair do |key,my_file|
        decade[key] = my_file["daterange"]
        if decade[key]
          if my_file["daterange"].length > max
            max = my_file["daterange"].length
          end
        end
      end
      decade["ba"] = Array.new(max, 0) unless decade["ba"]
      decade["bu"] = Array.new(max, 0) unless decade["bu"]
      decade["ma"] = Array.new(max, 0) unless decade["ma"]
      decade["total"]= Array.new(max, 0) unless decade["total"]
      decade
    end

    def get_places_for_display(chapman)
      places = Place.where(:chapman_code => chapman, :data_present => true,:disabled => 'false' ).all.order_by(place_name: 1)
      place_names = Array.new
      places.each do |place|
        place_names << place.place_name
      end
      place_names
    end

    def get_records_for_display(chapman)
      places = Place.where(:chapman_code => chapman, :data_present => true, :disabled => 'false').all.order_by(place_name: 1)
    end

    def get_transcribers(individual,my_hash,file)
      keys = ["ba","bu","ma"]
      total_keys = ["ba","bu","ma", "total"]
      if file == "file"
        keys.each do |key|
          my_hash["transcriber"][key] << individual.transcriber_name.strip.gsub(/\s+/, ' ').downcase.split.map(&:capitalize).join(' ') if individual.transcriber_name.present? && individual.record_type == key
          my_hash["contributor"][key] << individual.credit_name.strip.gsub(/\s+/, ' ').downcase.split.map(&:capitalize).join(' ') if individual.credit_name.present? && individual.record_type == key
        end
        keys.each do |key|
          my_hash["transcriber"]["total"] = my_hash["transcriber"]["total"] + my_hash["transcriber"][key] if  my_hash["transcriber"][key].present?
          my_hash["contributor"]["total"] = my_hash["contributor"]["total"] +  my_hash["contributor"][key] if my_hash["contributor"][key].present?
        end

        keys.each do |key|
          my_hash["transcriber"][key] =  my_hash["transcriber"][key].uniq
          my_hash["contributor"][key] = my_hash["contributor"][key].uniq
          my_hash["transcriber"][key].each do |entry|
            my_hash["contributor"][key].delete_if{ |value| value == entry}
          end
        end
        my_hash["transcriber"]["total"] = my_hash["transcriber"]["total"].uniq
        my_hash["contributor"]["total"] = my_hash["contributor"]["total"].uniq
        my_hash["transcriber"]["total"].each do |entry|
          my_hash["contributor"]["total"].delete_if{ |value| value == entry}
        end
      else
        total_keys.each do |key|
          my_hash["transcriber"][key] = my_hash["transcriber"][key] + individual["transcribers"][key] if individual["transcribers"][key].present?
          my_hash["contributor"][key] = my_hash["contributor"][key] + individual["contributors"][key] if individual["contributors"][key].present?
        end
        total_keys.each do |key|
          my_hash["transcriber"][key] = my_hash["transcriber"][key].uniq
          my_hash["contributor"][key] = my_hash["contributor"][key].uniq
          my_hash["transcriber"][key].each do |entry|
            my_hash["contributor"][key].delete_if{ |value| value == entry}
          end
        end
      end

    end

    def number_of_records_in_county(chapman)
      county = County.chapman_code(chapman).first
      record = Array.new
      record[0] = county.total_records
      record[1] = county.baptism_records
      record[2] = county.burial_records
      record[3] = county.marriage_records
      record
    end
    def setup_total_hash
      total_hash = Hash.new
      total_hash["ba"] = Array.new(50,0)
      total_hash["bu"] = Array.new(50,0)
      total_hash["ma"] = Array.new(50,0)
      total_hash["total"] = Array.new(50,0)
      return total_hash
    end

    def setup_transcriber_hash
      transcriber_hash = Hash.new
      transcriber_hash["transcriber"] = Hash.new
      transcriber_hash["transcriber"]["ba"] = Array.new
      transcriber_hash["transcriber"]["bu"] = Array.new
      transcriber_hash["transcriber"]["ma"] = Array.new
      transcriber_hash["transcriber"]["total"] = Array.new
      transcriber_hash["contributor"] = Hash.new
      transcriber_hash["contributor"]["ba"] = Array.new
      transcriber_hash["contributor"]["bu"] = Array.new
      transcriber_hash["contributor"]["ma"] = Array.new
      transcriber_hash["contributor"]["total"] = Array.new
      return transcriber_hash
    end
  end #self

  ###########################################################################        Instance methods
  def clean_blanks
    chapman_codes.delete_if { |x| x.blank? }
  end

  def county_is_valid
    if self.chapman_codes[0].nil?
      errors.add(:chapman_codes, "At least one county must be selected.")
    end
  end

  def get_alternate_place_names
    @names = Array.new
    @alternate_place_names = self.alternateplacenames.all
    @alternate_place_names.each do |acn|
      name = acn.alternate_name
      @names << name
    end
    @names
  end

  def place_ids_is_valid
    if self.place_ids.nil?
      errors.add(:place_ids, "At least one place must be selected. If there are none then there are no places transcribed")
    end
  end

  def search
    Place.where(search_params).order_by(:place_name.asc).all

  end

  def search_params
    params = Hash.new
    params[:chapman_code] = county if county
    params
  end

end
