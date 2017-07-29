class Register
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  require 'record_type'
  require 'register_type'
  require 'freereg_validations'


  field :status, type: String
  field :register_name,  type: String
  field :alternate_register_name,  type: String
  field :register_type,  type: String
  field :quality,  type: String
  field :source,  type: String
  field :copyright,  type: String
  field :register_notes,  type: String
  field :last_amended, type: String
  field :minimum_year_for_register
  field :maximum_year_for_register
  field :credit, type: String
  field :credit_from_files, type: String

  field :records, type: String
  field :datemin, type: String
  field :datemax, type: String
  field :daterange, type: Hash
  field :transcribers, type: Hash
  field :contributors, type: Hash
  has_many :freereg1_csv_files, dependent: :restrict
  belongs_to :church, index: true

  has_many :sources # includes origin server of images

  index({ church_id: 1, register_name: 1})
  index({ register_name: 1})
  index({ alternate_register_name: 1})
  index({ church_id: 1, alternate_register_name: 1})

  class << self
    def id(id)
      where(:id => id)
    end

    def create_register_for_church(args,freereg1_csv_file)
      # look for the church
      if @@my_church
        # locate place
        my_place = @@my_church.place
      else
        #church does not exist so see if Place exists
        my_place = Place.where(:chapman_code => args[:chapman_code], :place_name => args[:place_name],:disabled => 'false', :error_flag.ne => "Place name is not approved").first
        my_place = Place.where(:chapman_code => args[:chapman_code], :modified_place_name => args[:place_name].gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase, :disabled => 'false', :error_flag.ne => "Place name is not approved").first if my_place.nil?
        unless my_place
          #place does not exist so lets create new place first
          my_place = Place.new(:chapman_code => args[:chapman_code], :place_name => args[:place_name], :disabled => 'false', :grid_reference => 'TQ336805')
          my_place.error_flag = "Place name is not approved"
          my_place.save
        end
        #now create the church entry
        @@my_church = Church.new(:church_name => args[:church_name])
        my_place.churches << @@my_church
      end
      #now create the register
      register_parameters = Hash[:register_type => args[:register_type],:alternate_register_name => args[:alternate_register_name],:last_amended => args[:last_amended]]
      register = Register.new(register_parameters)
      register.freereg1_csv_files << freereg1_csv_file
      @@my_church.registers << register
      @@my_church.save
      register
    end


    def find_register(args)
      @@my_church = Church.find_by_name_and_place(args[:chapman_code], args[:place_name], args[:church_name])
      if @@my_church
        my_church_id = @@my_church[:_id]
        register = Register.where(:church_id =>my_church_id, :alternate_register_name=> args[:alternate_register_name] ).first
        unless register then
          register = Register.where(:church_id =>my_church_id, :register_name=> args[:alternate_register_name] ).first
          unless register
            register = nil
          end
        end
      else
        register = nil
      end
      register
    end

    def update_or_create_register(freereg1_csv_file)
      # find if register exists
      register = find_register(freereg1_csv_file.to_register)
      if register
        #update register
        register.freereg1_csv_files << freereg1_csv_file
        #freereg1_csv_file.save
      else
        # create the register
        register = create_register_for_church(freereg1_csv_file.to_register, freereg1_csv_file)
      end
      register.update_userid_with_new_file(freereg1_csv_file)
      register.update_data_present_in_place(freereg1_csv_file)
    end

  end #self

  ######################################################################## instance methods

  def calculate_register_numbers

    records = 0
    total_hash = FreeregContent.setup_total_hash
    transcriber_hash = FreeregContent.setup_transcriber_hash
    datemax = FreeregValidations::YEAR_MIN.to_i
    datemin = FreeregValidations::YEAR_MAX.to_i
    last_amended = DateTime.new(1998,1,1)
    individual_files = self.freereg1_csv_files
    if individual_files.present?
      individual_files.each do |file|
        if !file.records.nil? &&  file.records.to_i > 0
          records = records + file.records.to_i unless file.records.blank?
          datemax = file.datemax.to_i if file.datemax.to_i > datemax && file.datemax.to_i < FreeregValidations::YEAR_MAX unless file.datemax.blank?
          datemin = file.datemin.to_i if file.datemin.to_i < datemin unless file.datemin.blank?
          file.daterange = FreeregContent.setup_array if  file.daterange.blank?
          FreeregContent.calculate_date_range(file, total_hash,"file")
          FreeregContent.get_transcribers(file, transcriber_hash,"file")
          batch = PhysicalFile.userid(file.userid).file_name(file.file_name).first
          uploaded = batch.base_uploaded_date if batch.present?
          last_amended = uploaded.to_datetime  if uploaded.present? && uploaded.to_datetime > last_amended.to_datetime
        end
      end
    end
    datemax = '' if datemax == FreeregValidations::YEAR_MIN.to_i
    datemin = '' if datemin == FreeregValidations::YEAR_MAX.to_i
    last_amended.to_datetime == DateTime.new(1998,1,1)? last_amended = '' : last_amended = last_amended.strftime("%d %b %Y")
    self.update_attributes(:records => records,:datemin => datemin, :datemax => datemax, :daterange => total_hash, :transcribers => transcriber_hash["transcriber"],
                           :contributors => transcriber_hash["contributor"], :last_amended => last_amended   )
  end

  def change_type(type)
    old_type = self.register_type
    unless self.register_type == type
      self.update_attributes(:register_type => type, :alternate_register_name =>  self.church.church_name.to_s + " " + type.to_s )
    end
    if self.errors.any?
      return true
    end
    self.propogate_register_type_change(old_type)
    return false
  end

  def display_info
    @register = self
    #@register_name = @register.register_name
    #@register_name = @register.alternate_register_name if @register_name.nil?
    @register_name = RegisterType.display_name(@register.register_type)
    @church = @register.church
    @church_name = @church.church_name
    @place = @church.place
    @county =  @place.county
    @place_name = @place.place_name
    @user = cookies.signed[:userid]
    @first_name = @user.person_forename unless @user.blank?
  end

  def has_input?
    value = false
    value = true if (self.status.present? || self.quality.present? || self.source.present? || self.copyright.present?|| self.register_notes.present? ||
                     self.minimum_year_for_register.present? || self.maximum_year_for_register.present? )
    value
  end

  def merge_registers
    register_id = self._id
    church = self.church
    church.registers.each do |register|
      register.register_type
      unless (register._id == register_id || register.register_type != self.register_type)
        return [false, "a register being merged has input"] if register.has_input?
        register.freereg1_csv_files.each do |file|
          file.update_attribute(:register_id, register_id)
        end
        church.registers.delete(register)
      end
    end
    return [true, ""]
  end

  def propogate_register_type_change(old_type)
    place = self.church.place
    place_name = place.place_name
    church_name = self.church.church_name
    new_register_type = RegisterType.display_name(self.register_type)
    old_location_names =[]
    old_location_names << "#{place_name} (#{church_name})"
    old_location_names  << " [#{RegisterType.display_name(old_type)}]"
    new_location_names =[]
    new_location_names << "#{place_name} (#{church_name})"
    new_location_names[1] = " [#{new_register_type}]"
    result = SearchRecord.collection.find({place_id: place._id, location_names: old_location_names}).hint("place_location").update_many({"$set" => {:location_names => new_location_names}})
    files = self.freereg1_csv_files
    files.each do |file|
      result = Freereg1CsvEntry.collection.find({freereg1_csv_file_id: file.id}).hint("freereg1_csv_file_id_1").update_many({"$set" => {:register_type => self.register_type}})
      file.update_attribute(:register_type,self.register_type)
    end
  end


  def update_data_present_in_place(file)
    #also refresh the cache if the place is newly active
    place = self.church.place
    refresh_cache = false
    if place.present?
      cache = PlaceCache.where(:chapman_code => place.chapman_code).first
      place.update_attribute(:data_present, true)
      if cache.present?
        actual_cache = cache.places_json
        refresh_cache = true unless actual_cache.include?(place.place_name)
      end
    end
    PlaceCache.refresh(place.chapman_code) if refresh_cache
  end

  def update_userid_with_new_file(file)
    user =UseridDetail.where(:userid => file.userid).first
    user.freereg1_csv_files << file
    user.save(validate: false)
  end

end
