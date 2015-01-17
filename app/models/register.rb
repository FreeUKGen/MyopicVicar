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
  end

  def self.create_register_for_church(args,freereg1_csv_file)
    # look for the church
    if @@my_church
      # locate place
      my_place = @@my_church.place

    else
      #church does not exist so see if Place exists
      my_place = Place.where(:chapman_code => args[:chapman_code], :place_name => args[:place_name],:disabled => 'false').first
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

  def self.clean_empty_registers(register)
    #clean out empty register/church/places
    unless register.freereg1_csv_files.exists?
      church = register.church
      place = church.place
      church.registers.where(:alternate_register_name => register.alternate_register_name).delete_all if place.error_flag == "Place name is not approved" || !register.has_input?
      place.churches.where(:church_name => church.church_name).delete_all if !church.registers.exists? && !church.has_input?
      place.update_attributes(:data_present => false) unless place.search_records.exists?
      place.destroy if !place.search_records.exists? && place.error_flag == "Place name is not approved"
    end
  end

  def change_type(type)
    p 'updating register type'
    p self
    p type
    unless self.register_type == type
      self.update_attributes(:register_type => type, :alternate_register_name =>  self.church.church_name.to_s + " " + type.to_s )
      self.freereg1_csv_files.each do |file|
        p 'updating file '
        p file
        file.update_attributes(:register_type => type)
        file.update_entries_and_search_records_for_type(type)
      end #file
    end
    if self.errors.any?
      return true
    end
    return false
  end

  def merge_registers
    p 'merging'
    p self
    register_id = self._id
    p register_id
    p self.register_type
    church = self.church
    p church
    church.registers.each do |register|
      p 'loop registers'
      p register
      p register._id
      register.register_type
      if (register._id == register_id || register.register_type != self.register_type)

        p 'bypassed'
      else
        p 'merging this register'
        p register
        return [true, "a register being merged has input"] if register.has_input?
        register.freereg1_csv_files.each do |file|
          p 'updating file '
          p file
          file.update_attributes(:register_id => register_id)
        end
        p ' removing register'
        p register
        church.registers.delete(register)
      end
    end
    return [false, ""]
  end

  def has_input?
    value = false
    value = true if (self.status.present? || self.quality.present? || self.source.present? || self.copyright.present?|| self.register_notes.present? ||
                     self.minimum_year_for_register.present? || self.maximum_year_for_register.present? )
    p 'has input'
    p value
    value
  end
end
