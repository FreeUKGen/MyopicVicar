class Assignment
  include Mongoid::Document
  
  field :instructions, type: String
  field :assign_date, type: String

  attr_accessor :user_id

  belongs_to :source, index: true
  belongs_to :userid_detail, index: true
  has_many :image_server_images #, index: true
  # TODO: Should an assignment be associated with pages at the record level?

  class << self

    def bulk_update_assignment(assignment_id,orig_status,new_status)
      assignment = Assignment.id(assignment_id)
      image_server_image = ImageServerImage.where(:assignment_id=>assignment_id, :status=>orig_status)

      assignment_list = assignment.pluck(:id)
      image_list = image_server_image.pluck(:id).map {|x| x.to_s}

      Assignment.update_original_assignments(assignment_list,'',image_list)
      image_server_image.update_all(:assignment_id=>nil, :status=>new_status)
    end

  	def create_assignment(source_id, user_id, instructions)
      source = Source.id(source_id).first
      userid_detail = UseridDetail.id(user_id).first
      assignment = Assignment.new(:source_id=>source_id, :userid_detail_id=>user_id)
      assignment.instructions = instructions
      assignment.assign_date = Time.now.iso8601

      assignment.save
      source.assignments << assignment
      source.save
      userid_detail.assignments << assignment
      userid_detail.save
    end

    def id(id)
      where(:id => id)
    end

    def source_id(id)
      where(:source_id=>id)
    end

    def update_or_create_new_assignment(source_id,user_id,instructions,image_list,image_status)
      orig_assignment = ImageServerImage.where(:id=>{'$in'=>image_list}).pluck(:assignment_id).uniq
      dest_assignment = Assignment.where(:source_id=>source_id, :userid_detail_id=>user_id)

      if dest_assignment.nil? || dest_assignment.empty?
        Assignment.create_assignment(source_id, user_id, instructions)
        dest_assignment = Assignment.where(:source_id=>source_id, :userid_detail_id=>user_id)
      else
        dest_assignment.update_all(:assign_date=>Time.now.iso8601)
      end

      Assignment.update_original_assignments(orig_assignment,dest_assignment.first.id,image_list)

      if image_status.nil?
        ImageServerImage.where(:id=>{'$in'=>image_list}).update_all(:assignment_id=>dest_assignment.first.id)
      else
        ImageServerImage.where(:id=>{'$in'=>image_list}).update_all(:assignment_id=>dest_assignment.first.id, :status=>image_status)
      end
    end

    def update_original_assignments(assignment,dest_assignment_id,assign_list)
      images_by_assignment_id = ImageServerImage.where(:assignment_id=>{'$in'=>assignment}).pluck(:assignment_id, :id).uniq
      hash_images_by_assignment_id = Hash.new{|h,k| h[k]=[]}.tap{|h| images_by_assignment_id.each{|k,v| h[k] << v}}

      hash_images_by_assignment_id.each do |assignment_id,image_ids|
        image_ids.each do |image_id|
          image_ids = image_ids - [image_id] if assign_list.include? image_id.to_s
        end
        hash_images_by_assignment_id[assignment_id] = image_ids
      end

      if !hash_images_by_assignment_id.nil?
        hash_images_by_assignment_id.keys.each do |assignment_id|
          assignment = Assignment.id(assignment_id)
          assignment.destroy if hash_images_by_assignment_id[assignment_id].empty? && assignment_id != dest_assignment_id
        end
      end
    end

    def user_id(id)
      where(:userid_detail_id=>id)
    end

  end
end
