class Church

  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  require 'register_type'
  require 'freereg_options_constants'
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
  field :unique_surnames, type: Array
  field :unique_forenames, type: Array
  has_many :registers, dependent: :restrict_with_error
  has_many :image_server_groups
  embeds_many :alternatechurchnames
  accepts_nested_attributes_for :alternatechurchnames, allow_destroy: true,  reject_if: :all_blank

  belongs_to :place, index: true
  index({ place_id: 1, church_name: 1 })

  ############################################################# class methods

  class << self
    def id(id)
      where(:id => id)
    end

    def find_by_place_ids(id)
      where(:place_id => {'$in'=>id.keys})
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

    def church_valid?(church)
      if church.blank?
        logger.warn("#{MyopicVicar::Application.config.freexxx_display_name.upcase}:CHURCH_ERROR: file had no church")
        result = false
      elsif Church.find_by(id: church.id).present?
        result = true
      else
        result = false
        logger.warn("#{MyopicVicar::Application.config.freexxx_display_name.upcase}:CHURCH_ERROR: #{church.id} not located")
      end
      result
    end

    def valid_church?(church)
      result = false
      return result if church.blank?

      church_object = Church.find(church)
      result = true if church_object.present? && Place.valid_place?(church_object.place_id)
      logger.warn("FREEREG:LOCATION:VALIDATION invalid church id #{church} ") unless result
      result
    end
  end # self

  ############################################################################## instance methods

  def calculate_church_numbers
    records = 0
    total_hash = FreeregContent.setup_total_hash
    transcriber_hash = FreeregContent.setup_transcriber_hash
    datemax = FreeregValidations::YEAR_MIN.to_i
    datemin = FreeregValidations::YEAR_MAX.to_i
    last_amended = DateTime.new(1998, 1, 1)
    individual_registers = self.registers
    if individual_registers.present?
      individual_registers.each do |register|
        if register.records.present? && register.records.to_i > 0 && register["transcribers"]
          records = records + register.records.to_i if register.records.present?
          datemax = register.datemax.to_i if register.datemax.present? && (register.datemax.to_i > datemax) && (register.datemax.to_i < FreeregValidations::YEAR_MAX)
          datemin = register.datemin.to_i if register.datemin.present? && (register.datemin.to_i < datemin)
          register.daterange = FreeregContent.setup_total_hash if register.daterange.blank?
          FreeregContent.calculate_date_range(register, total_hash, "register")
          FreeregContent.get_transcribers(register, transcriber_hash, "register")
          last_amended = register.last_amended.to_datetime if register.present? && register.last_amended.present? && (register.last_amended.to_datetime > last_amended.to_datetime)
        end
      end
    end
    datemax = '' if datemax == FreeregValidations::YEAR_MIN.to_i
    datemin = '' if datemin == FreeregValidations::YEAR_MAX.to_i
    last_amended = last_amended.to_datetime == DateTime.new(1998, 1, 1) ? '' : last_amended.strftime("%d %b %Y")
    self.update_attributes(records: records, datemin: datemin, datemax: datemax, daterange: total_hash, transcribers: transcriber_hash["transcriber"],
                           last_amended: last_amended)
  end

  def change_name(param)
    old_church_name = self.church_name
    unless old_church_name == param[:church_name]
      param[:church_name] = Church.standardize_church_name(param[:church_name])
      self.update_attribute(:church_name, param[:church_name])
    end
    if self.errors.any?
      return false
    end
    self.propogate_church_name_change(old_church_name)
    return true
  end

  def church_does_not_exist(place)
    return false, "Church name cannot be blank" unless self.church_name.present?
    self.church_name = self.church_name.strip
    place.churches.each do |church|
      if church.church_name == self.church_name
        return false, "Church of that name already exists"
      end
    end
    return true,''
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

  def get_alternate_church_names
    names = Array.new
    alternate_church_names = self.alternatechurchnames.all
    alternate_church_names.each do |acn|
      name = acn.alternate_name
      names << name
    end
    names
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
        return [false, "a church being merged has input"] if church.has_input?
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
    return [true, '']
  end

  def my_registers
    ordered_registers = []
    FreeregOptionsConstants::REGISTER_TYPE_ORDER.each do |type|
      registers.each do |register|
        ordered_registers << register if type == RegisterType.display_name(register.register_type)
      end
    end
    ordered_registers
  end

  def propogate_church_name_change(old_church_name)
    place = self.place
    place_name = place.place_name
    old_location = "#{place_name} (#{old_church_name})"
    new_location = "#{place_name} (#{self.church_name})"
    result = SearchRecord.collection.find({place_id: place._id, location_names: old_location}).hint("place_location").update_many({"$set" => {"location_names.$" => new_location}})
    all_registers = self.registers
    all_registers.each do |register|
      all_files = register.freereg1_csv_files
      all_files.each do |file|
        result = Freereg1CsvEntry.collection.find({freereg1_csv_file_id: file.id}).hint("freereg1_csv_file_id_1").update_many({"$set" => {:church_name => self.church_name}})
        file.update_attributes(:church_name => self.church_name)
      end
    end
  end

  def propogate_place_change(new_place, old_place)
    new_place_name = new_place.place_name
    new_place_id = new_place.id
    new_chapman_code = new_place.chapman_code
    old_place_name = old_place.place_name
    old_location = Array.new
    new_location = Array.new
    old_location[0] = "#{old_place_name} (#{church_name})"
    new_location[0] = "#{new_place_name} (#{church_name})"
    all_registers = registers
    all_registers.each do |register|
      type = register.register_type
      old_location[1] = " [#{RegisterType.display_name(type)}]"
      new_location[1] = " [#{RegisterType.display_name(type)}]"
      all_files = register.freereg1_csv_files
      all_files.each do |file|
        records = file.freereg1_csv_entries.count
        file.freereg1_csv_entries.each do |entry|
          record = entry.search_record
          logger.warn("FREEREG:PLACE:PROPAGATION entry #{entry.id} has no search_record ") if record.blank?
          record.update(location_names: new_location, place_id: new_place_id, chapman_code: new_chapman_code) if record.present?
          entry.update(county: new_chapman_code, place: new_place_name)
        end
        file.update(place: new_place_name, place_name: new_place_name, county: new_chapman_code)
      end
      register.update(last_amended: Time.zone.today.strftime("%e %b %Y"))
    end
  end

  def relocate_church(param)
    if param[:place_name].blank? || param[:place_name] == self.place.place_name
      [false, 'No change in place']
    else
      old_place = place
      chapman_code = old_place.chapman_code
      new_place = Place.find_by(chapman_code: chapman_code, place_name: param[:place_name])
      param[:county] = chapman_code if param[:county].blank?
      update(place_id: new_place.id, place_name: param[:place_name])
      propogate_place_change(new_place, old_place)
      update(place_id: new_place.id, place_name: param[:place_name], last_amended: Time.zone.today.strftime("%e %b %Y"))
      new_place.calculate_place_numbers
      old_place.reload
      old_place.calculate_place_numbers
      [false, 'Error in save of church; contact the webmaster'] if self.errors.any?

      PlaceCache.refresh_cache(new_place) unless new_place.blank?
      [true, '']
    end
  end
end
