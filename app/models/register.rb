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
  field :unique_surnames, type: Array
  field :unique_forenames, type: Array
  has_many :freereg1_csv_files, dependent: :restrict_with_error
  belongs_to :church, index: true

  has_many :sources, dependent: :restrict_with_error # includes origin server of images
  has_many :embargo_rules
  has_many :gaps

  index({ church_id: 1, register_name: 1})
  index({ register_name: 1})
  index({ alternate_register_name: 1})
  index({ church_id: 1, alternate_register_name: 1})

  class << self
    def id(id)
      where(:id => id)
    end

    def check_and_correct_register_type(register_type)
      if !(RegisterType.approved_option_values.include?(register_type) || RegisterType.option_values.include?(register_type))
        register_type = RegisterType::OPTIONS[register_type] if RegisterType.option_keys.include?(register_type)
        register_type = RegisterType::APPROVED_OPTIONS[register_type] if RegisterType.approved_option_keys.include?(register_type)
      end
      register_type
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

    def create_folder_url(chapman_code,folder_name,register)
      URI.escape(Rails.application.config.image_server + 'manage_freereg_images/create_folder?chapman_code=' + chapman_code + '&folder_name=' + folder_name +  '&register=' + register + '&image_server_access=' + Rails.application.config.image_server_access)
    end

    def find_by_church_ids(id)
      Register.where(:church_id => {'$in'=>id.keys})
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

    def image_transcriptions_calculation(register_id)
      images = Hash.new()

      source = Source.where(:register_id=>register_id).pluck(:id, :source_name)
      return {} if source.empty? || source == [''] || source == [nil]

      @source_name = Hash.new{|h,k| h[k]=[]}.tap{|h| source.each{|k,v| h[k] = v}}
      source_ids = source.map {|k,v| k}

      image_server_group = ImageServerGroup.where(:source_id=>{'$in'=>source_ids}).pluck(:id, :group_name, :source_id, :number_of_images)
      return {} if image_server_group.empty? || image_server_group == [''] || image_server_group == [nil]

      image_server_group_ids = image_server_group.map {|k,v1,v2,v3| k}
      group_name = Hash.new{|h,k| h[k]=[]}.tap{|h| image_server_group.each{|k,v1,v2,v3| h[k] = v1}}
      group_in_source = Hash.new{|h,k| h[k]=[]}.tap{|h| image_server_group.each{|k,v1,v2,v3| h[k] = v2}}
      total_images = Hash.new{|h,k| h[k]=[]}.tap{|h| image_server_group.each{|k,v1,v2,v3| h[k] = v3}}

      image_server_image = ImageServerImage.where(:image_server_group_id=>{'$in'=>image_server_group_ids})

      image_server_image.each do |x|
        s_id = group_in_source[x.image_server_group_id]
        g_name = group_name[x.image_server_group_id]

        if ['u','a','bt','ts','br','rs'].include?(x.status)
          images[s_id] = Hash.new() if images[s_id].nil?
          images[s_id][g_name] = Hash.new() if images[s_id][g_name].nil?
          images[s_id][g_name][:count] = total_images[x.image_server_group_id]
        end

        case x.status
        when 'u'
          images[s_id][g_name][:unallocated] = images[s_id][g_name][:unallocated].nil? ? 1 : images[s_id][g_name][:unallocated] + 1
        when 'a'
          images[s_id][g_name][:allocated] = images[s_id][g_name][:allocated].nil? ? 1 : images[s_id][g_name][:allocated] + 1
        when 'bt'
          images[s_id][g_name][:being_transcribed] = images[s_id][g_name][:being_transcribed].nil? ? 1 : images[s_id][g_name][:being_transcribed] + 1
        when 'ts'
          images[s_id][g_name][:transcription_submitted] = images[s_id][g_name][:transcription_submitted].nil? ? 1 : images[s_id][g_name][:transcription_submitted] + 1
        when 'br'
          images[s_id][g_name][:being_reviewed] = images[s_id][g_name][:being_reviewed].nil? ? 1 : images[s_id][g_name][:being_reviewed] + 1
        when 'rs'
          images[s_id][g_name][:review_submitted] = images[s_id][g_name][:review_submitted].nil? ? 1 : images[s_id][g_name][:review_submitted] + 1
        end
      end

      images.each do |s_id,v1|
        v1.each do |g_name,v2|
          images[s_id][g_name][:in_progress] = (v2[:being_transcribed].nil? ? ''.to_i : v2[:being_transcribed]) + (v2[:transcription_submitted].nil? ? ''.to_i : v2[:transcription_submitted]) + (v2[:being_reviewed].nil? ? ''.to_i : v2[:being_reviewed]) + (v2[:review_submitted].nil? ? ''.to_i : v2[:review_submitted])
          images[s_id][g_name][:available] = (v2[:unallocated].nil? ? ''.to_i : v2[:unallocated]) + (v2[:allocated].nil? ? ''.to_i : v2[:allocated])
        end
      end

      return images
    end

    def register_valid?(register)
      if register.blank?
        logger.warn("#{App.name.upcase}:REGISTER_ERROR: file had no register")
        result = false
      elsif Register.find_by(id: register.id).present?
        result = true
      else
        result = false
        logger.warn("#{App.name.upcase}:REGISTER_ERROR: #{register.id} not located")
      end
      result
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

    def valid_register?(register)
      result = false
      return result if register.blank?

      register_object = Register.find(register)
      result = true if register_object.present? && Church.valid_church?(register_object.church_id)
      logger.warn("FREEREG:LOCATION:VALIDATION invalid register id #{register} ") unless result
      result
    end

  end #self

  ######################################################################## instance methods


  def add_source(folder_name)
    proceed = true
    message = ''
    self.sources.each do |source|
      if source.source_name == "Image Server"
        proceed = false
        message = 'Image Server already exists'
      end
    end
    if proceed
      source = Source.new(:source_name => "Image Server",:folder_name => folder_name)
      self.sources << source
      self.save
    end
    return proceed, message
  end

  def add_little_gems_source(folder_name)
     proceed = true
    message = ''
    self.sources.each do |source|
      if source.source_name == "Little Gems"
        proceed = false
        message = 'Little Gems source exists'
      end
    end
    if proceed
      source = Source.new(:source_name => "Little Gems",:folder_name => folder_name)
      self.sources << source
      self.save
    end
    return proceed, message
  end

  def calculate_register_numbers
    records = 0
    total_hash = FreeregContent.setup_total_hash
    transcriber_hash = FreeregContent.setup_transcriber_hash
    datemax = FreeregValidations::YEAR_MIN.to_i
    datemin = FreeregValidations::YEAR_MAX.to_i
    last_amended = DateTime.new(1998, 1, 1)
    individual_files = self.freereg1_csv_files
    if individual_files.present?
      individual_files.each do |file|
        if file.records.present? && file.records.to_i > 0
          records = records + file.records.to_i if file.records.present?
          datemax = file.datemax.to_i if file.datemax.present? && (file.datemax.to_i > datemax) && (file.datemax.to_i < FreeregValidations::YEAR_MAX)
          datemin = file.datemin.to_i if file.datemin.present? && file.datemin.to_i < datemin
          file.daterange = FreeregContent.setup_array if file.daterange.blank?
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
    last_amended.to_datetime == DateTime.new(1998, 1, 1)? last_amended = '' : last_amended = last_amended.strftime("%d %b %Y")
    self.update_attributes(:records => records, :datemin => datemin, :datemax => datemax, :daterange => total_hash, :transcribers => transcriber_hash["transcriber"],
                           :last_amended => last_amended   )
  end

  def can_create_image_source
    proceed = true
    if self.register_type.nil? || self.register_type == ' '
      proceed = false
      message = 'Cannot create source for unspecified register'
    end
    return proceed, message
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
    @user = get_user
    @first_name = @user.person_forename unless @user.blank?
  end

  def embargo_rules_exist?
    embargo_rules = self.embargo_rules.present? ? true : false
    embargo_rules
  end

  def gaps_exist?
    gaps = self.gaps.present? ? true : false
    gaps
  end

  def has_input?
    value = false
    value = true if (self.status.present? || self.quality.present? || self.source.present? || self.copyright.present?|| self.register_notes.present? ||
                     self.minimum_year_for_register.present? || self.maximum_year_for_register.present? )
    value
  end

  def image_servers_exist?
    image_server = false
    unless self.sources.nil?
      self.sources.each do |source|
        image_server = true if source.source_name == "Image Server"
      end
    end
    image_server
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
