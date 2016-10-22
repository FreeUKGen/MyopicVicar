class Church

  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  require 'register_type'
  field :church_name,type: String
  field :last_amended, type: String
  field :denomination, type: String
  field :location, type: String, default: ''
  field :place_name, type: String
  field :church_notes, type: String
  field :website, type: String, default: ''
  field :records, type: String
  field :datemin, type: String
  field :datemax, type: String
  field :daterange, type: Hash
  field :transcribers, type: Hash
  field :contributors, type: Hash
  has_many :registers, dependent: :restrict

  embeds_many :alternatechurchnames
  accepts_nested_attributes_for :alternatechurchnames, allow_destroy: true,  reject_if: :all_blank

  belongs_to :place, index: true
  index({ place_id: 1, church_name: 1 })

  ############################################################# class methods

  class << self
    def id(id)
      where(:id => id)
    end

    def find_by_name_and_place(chapman_code, place_name,church_name)
      #see if church exists
      my_place = Place.where(:chapman_code => chapman_code, :place_name => place_name,:disabled => "false").first
      if my_place
        my_place_id = my_place[:_id]
        my_church = Church.where(:place_id => my_place_id, :church_name => church_name).first
      else
        my_church = nil
      end
      return my_church
    end

    def standardize_church_name(word)
      word = word.gsub(/\./, " ").gsub(/\s+/, ' ').strip
      church_words = word.split(" ")
      new_church_word = ""
      church_words.each do |church_word|
        church_word = FreeregOptionsConstants::CHURCH_WORD_EXPANSIONS[church_word] if FreeregOptionsConstants::CHURCH_WORD_EXPANSIONS.has_key?(church_word)
        church_word = FreeregOptionsConstants::COMMON_WORD_EXPANSIONS[church_word] if FreeregOptionsConstants::COMMON_WORD_EXPANSIONS.has_key?(church_word)
        new_church_word = new_church_word + church_word + " "
      end
      word = new_church_word.strip
      return word
    end

  end #self

  ############################################################################## instance methods

  def calculate_church_numbers
    records = 0
    total_hash = FreeregContent.setup_total_hash
    transcriber_hash = FreeregContent.setup_transcriber_hash
    datemax = FreeregValidations::YEAR_MIN.to_i
    datemin = FreeregValidations::YEAR_MAX.to_i
    individual_registers = self.registers
    if individual_registers.present?
      individual_registers.each do |register|
        if !register.records.nil? &&  register.records.to_i > 0 && register["transcribers"] && register["contributors"]
          records = records + register.records.to_i unless register.records.blank?
          datemax = register.datemax.to_i if register.datemax.to_i > datemax && register.datemax.to_i < FreeregValidations::YEAR_MAX unless register.datemax.blank?
          datemin = register.datemin.to_i if register.datemin.to_i < datemin unless register.datemin.blank?
          register.daterange = FreeregContent.setup_total_hash if  register.daterange.blank?
          FreeregContent.calculate_date_range(register, total_hash,"register")
          FreeregContent.get_transcribers(register, transcriber_hash,"register")
        end
      end
    end
    datemax = '' if datemax == FreeregValidations::YEAR_MIN.to_i
    datemin = '' if datemin == FreeregValidations::YEAR_MAX.to_i
    self.update_attributes(:records => records,:datemin => datemin, :datemax => datemax, :daterange => total_hash, :transcribers => transcriber_hash["transcriber"], :contributors => transcriber_hash["contributor"])
  end

  def change_name(param)
    unless self.church_name == param[:church_name]
      param[:church_name] = Church.standardize_church_name(param[:church_name])
      self.update_attribute(:church_name, param[:church_name])
    end
    if self.errors.any?
      return true
    end
    self.propogate_church_name_change
    return false
  end

  def church_does_not_exist(place)
    return false, "Church name cannot be blank" unless self.church_name.present?
    self.church_name = self.church_name.strip
    place.churches.each do |church|
      if church.church_name == self.church_name
        return false, "Church of that name already exits"
      end
    end
    return true, "OK"
  end

  def data_contents
    min = Time.new.year
    max = 1500
    records = 0
    self.registers.each do |register|
      register.freereg1_csv_files.each do |file|
        min = file.datemin.to_i if file.datemin.to_i < min
        max = file.datemax.to_i if file.datemax.to_i > max
        records = records + file.records.to_i unless file.records.nil?
      end
    end
    stats =[records,min,max]
    return stats
  end

  def has_input?
    value = false
    value = true if (self.denomination.present? || self.church_notes.present? || self.location.present? || self.website.present?)
    value
  end

  def merge_churches
    new_church_id = self._id
    church_name = self.church_name
    place = self.place
    place.churches.each do |church|
      unless (church._id == new_church_id || church.church_name != church_name)
        return [true, "a church being merged has input"] if church.has_input?
      end
    end
    place.churches.each do |church|
      unless (church._id == new_church_id || church.church_name != church_name)
        church.registers.each do |register|
          register.update_attribute(:church_id, new_church_id)
        end
        place.churches.delete(church)
      end
    end
    self.calculate_church_numbers
    return [false, ""]
  end

  def propogate_church_name_change
    place = self.place
    place_name = place.place_name
    self.registers.no_timeout.each do |register|
      location_names = []
      location_names << "#{place_name} (#{self.church_name})"
      location_names  << " [#{RegisterType.display_name(register.register_type)}]"
      register.freereg1_csv_files.no_timeout.each do |file|
        file.freereg1_csv_entries.no_timeout.each do |entry|
          if entry.search_record.nil?
            logger.info "FREEREG:search record missing for entry #{entry._id}"
          else
            entry.update_attributes(:place => place_name, :church_name => self.church_name)
            record  = entry.search_record
            record.update_attributes(:location_names => location_names,:place_id => place.id, :chapman_code => place.chapman_code)
          end
        end
        file.update_attributes(:place => place_name, :church_name => self.church_name)
      end
    end

  end

  def relocate_church(param)
    unless param[:place_name].blank? || param[:place_name] == self.place.place_name
      old_place = self.place
      chapman_code = old_place.chapman_code
      new_place = Place.where(:chapman_code => chapman_code, :place_name => param[:place_name]).first
      param[:county] = chapman_code if param[:county].blank?
      self.update_attributes(:place_id => new_place._id, :place_name => param[:place_name])
      new_place.update_attribute(:data_present, true) if new_place.search_records.exists? && new_place.data_present == false
      new_place.recalculate_last_amended_date
      new_place.calculate_place_numbers
      self.calculate_place_numbers
      return [true, "Error in save of church; contact the webmaster"] if self.errors.any?
    end
    self.propogate_church_name_change
    PlaceCache.refresh_cache(new_place)
    return [false, ""]
  end


end
