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
  has_many :registers, dependent: :restrict

  embeds_many :alternatechurchnames
  accepts_nested_attributes_for :alternatechurchnames

  belongs_to :place, index: true
  index({ place_id: 1, church_name: 1 })
  validates_presence_of :church_name
  validate :church_does_not_exist, on: :create

  def church_does_not_exist
    #errors.add(:church_name, "Church of that name already exits") unless place.church.nil?
  end


  def self.find_by_name_and_place(chapman_code, place_name,church_name)
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
  def change_name(param)
    unless self.church_name == param[:church_name]
      self.update_attributes(:church_name => param[:church_name])
      self.registers.each do |register|

        type = register.register_type
        register.update_attributes(:alternate_register_name =>  self.church_name.to_s + " " + type.to_s )

        register.freereg1_csv_files.each do |file|

          file.update_attributes(:church_name => param[:church_name])
          file.update_entries_and_search_records_for_church(self.place.place_name,param[:church_name])
        end #file
      end
    end
    if self.errors.any?
      return true
    end
    return false
  end

  def merge_churches

    new_church_id = self._id

    church_name = self.church_name

    place = self.place


    place.churches.each do |church|

      if (church._id == new_church_id || church.church_name != church_name)

      else

        return [true, "a church being merged has input"] if church.has_input?
      end
    end

    place.churches.each do |church|

      if (church._id == new_church_id || church.church_name != church_name)

      else

        church.registers.each do |register|

          register.update_attributes(:church_id => new_church_id)

        end
        place.churches.delete(church)
      end

    end

    return [false, ""]
  end

  def relocate_church(param)
    unless param[:place_name].blank? || param[:place_name] == self.place.place_name

      old_place = self.place
      chapman_code = place.chapman_code
      new_place = Place.where(:chapman_code => chapman_code, :place_name => param[:place_name]).first
      param[:county] = old_place.chapman_code if param[:county].blank?
      self.update_attributes(:place_id => new_place._id, :place_name => param[:place_name])
      return [true, "Error in save of church; contact the webmaster"] if self.errors.any?
      self.registers.each do |register|

        register.freereg1_csv_files.each do |file|

          file.update_attributes(:place => param[:place_name])
          return [true, "Error in save of file; contact the webmaster"] if file.errors.any?

          file.update_entries_and_search_records_for_place(new_place,self.church_name)
        end #file
      end
    end
    return [false, ""]
  end

  def has_input?
    value = false
    value = true if (self.denomination.present? || self.church_notes.present? || self.location.present? || self.website.present?)

    value
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
end
