class Register
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  require 'record_type'
  require 'register_type'

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

  has_many :freereg1_csv_files, dependent: :restrict
  belongs_to :church, index: true


  index({ church_id: 1, register_name: 1})
  index({ register_name: 1})
  index({ alternate_register_name: 1})
  index({ church_id: 1, alternate_register_name: 1})




  def self.update_or_create_register(freereg1_csv_file)

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
    user =UseridDetail.where(:userid => freereg1_csv_file.userid).first
    user.freereg1_csv_files << freereg1_csv_file
    user.save(validate: false)
  end

  def self.create_register_for_church(args,freereg1_csv_file)
    # look for the church
    if @@my_church
      # locate place
      my_place = @@my_church.place

    else
      #church does not exist so see if Place exists
      my_place = Place.where(:chapman_code => args[:chapman_code], :place_name => args[:place_name],:disabled => 'false', :error_flag.ne => "Place name is not approved").first
      unless my_place
        #place does not exist so lets create new place first
        my_place = Place.new(:chapman_code => args[:chapman_code], :place_name => args[:place_name], :disabled => 'false', :grid_reference => 'TQ336805')

        my_place.error_flag = "Place name is not approved"
      end
      #now create the church entry
      @@my_church = Church.new(:church_name => args[:church_name])
      my_place.churches << @@my_church
    end
    #now create the register
    register = Register.new(args)
    register.freereg1_csv_files << freereg1_csv_file



    @@my_church.registers << register
    @@my_church.save
    #and save everything

    my_place.data_present = true

    my_place.save!
    #freereg1_csv_file.save
    register
  end

  def records
    records = 0
    @self.freereg1_csv_files.each do |file|
      records =  records + file.freereg1_csv_entries.count
    end
    records
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
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
  end
  


  def self.find_register(args)

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

  def propogate_register_type_change
      location_names =[]
      place_name = self.church.place.place_name
      church_name = self.church.church_name
      location_names << "#{place_name} (#{church_name})"
      location_names  << " [#{self.register_type}]"
        register.freereg1_csv_files do |file|
          file.entries.each do |entry|
            entry.search_record.update_attribute(:location_names, location_names)
          end
        end 
  end



  def change_type(type)
    unless self.register_type == type
      self.update_attributes(:register_type => type, :alternate_register_name =>  self.church.church_name.to_s + " " + type.to_s )
    end
    if self.errors.any?
      return true
    end
    return false
  end

  def merge_registers
    register_id = self._id
    church = self.church
    church.registers.each do |register|
      register.register_type
      unless (register._id == register_id || register.register_type != self.register_type)
        return [true, "a register being merged has input"] if register.has_input?
        register.freereg1_csv_files.each do |file|
          file.update_attribute(:register_id, register_id)
        end
        church.registers.delete(register)
      end
    end
    return [false, ""]
  end

  def has_input?
    value = false
    value = true if (self.status.present? || self.quality.present? || self.source.present? || self.copyright.present?|| self.register_notes.present? ||
                     self.minimum_year_for_register.present? || self.maximum_year_for_register.present? )
    value
  end
end
