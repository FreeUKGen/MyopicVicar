class Assignment
  include Mongoid::Document
  
  field :instructions, type: String
  field :assign_date, type: String

  attr_accessor :user_id

  belongs_to :source, index: true
  belongs_to :syndicate, index: true
  belongs_to :userid_detail, index: true
  has_many :image_server_images #, index: true
  # TODO: Should an assignment be associated with pages at the record level?

  class << self

    def bulk_update_assignment(assignment_id,type,orig_status,new_status)
      assignment = Assignment.id(assignment_id)
      image_server_image = ImageServerImage.where(:assignment_id=>assignment_id, :status=>orig_status)
      image_server_group = ImageServerGroup.where(:id=>image_server_image.first.image_server_group.id)
      user = UseridDetail.where(:id=>assignment.first.userid_detail_id).first.userid

      assignment_list = assignment.pluck(:id)
      image_list = image_server_image.pluck(:id).map {|x| x.to_s}

      Assignment.update_original_assignments(assignment_list,'',image_list)

      case type
        when 'complete'
          case new_status
            when 't'
              image_server_image.update_all(:assignment_id=>nil, :status=>new_status, :transcriber=>[user])
            when 'r'
              image_server_image.update_all(:assignment_id=>nil, :status=>new_status, :reviewer=>[user])
          end
        when 'unassign'
          case new_status
            when 'a'
              image_server_image.update_all(:assignment_id=>nil, :status=>new_status, :transcriber=>[''])
            when 't'
              image_server_image.update_all(:assignment_id=>nil, :status=>new_status, :reviewer=>[''])
          end
        when 'error'
          image_server_image.update_all(:assignment_id=>nil, :status=>new_status, :reviewer=>[user])
      end

      ImageServerImage.refresh_src_dest_group_summary(image_server_group)
    end

  	def create_assignment(source_id,user_id,instructions,assign_list,image_status)
      source = Source.id(source_id).first
      userid_detail = UseridDetail.id(user_id).first
      assignment = Assignment.new(:source_id=>source_id, :userid_detail_id=>user_id.id)
      assignment.instructions = instructions
      assignment.assign_date = Time.now.iso8601

      syndicate_code = userid_detail.syndicate
      syndicate = Syndicate.syndicate_code(syndicate_code).first
      assignment.syndicate_id = syndicate._id
      assignment.source_id = source.id
      assignment.userid_detail_id = userid_detail.id
      assignment.save

      assign_image_server_image_to_assignment(assignment.id,user_id,assign_list,image_status)
    end

    def filter_assignments_by_assignment_id(assignment_id)
      a_ids = Assignment.where(:id=>assignment_id).pluck(:id, :source_id, :assign_date, :instructions, :userid_detail_id)
      assignment_id = Hash.new{|h,k| h[k]=[]}.tap{|h| a_ids.each{|k,v1,v2,v3,v4| h[k] << v1 << v2 << v3 << v4}}

      u_ids = UseridDetail.where(:id=>a_ids[0][4]).pluck(:id,:userid)
      userid = Hash.new{|h,k| h[k]=[]}.tap{|h| u_ids.each{|k,v| h[k] = v}}

      i_ids = ImageServerImage.where(:assignment_id=>a_ids[0][0]).pluck(:id, :assignment_id, :image_server_group_id, :image_file_name, :status, :difficulty, :notes)
      image_assignment_id = Hash.new{|h,k| h[k]=[]}.tap{|h| i_ids.each{|k,v1,v2| h[k] = v1}}
      image_group_id = Hash.new{|h,k| h[k]=[]}.tap{|h| i_ids.each{|k,v1,v2,v3| h[k] = v2}}
      image = Hash.new{|h,k| h[k]=[]}.tap{|h| i_ids.each{|k,v1,v2,v3,v4,v5,v6| h[k] << v3 << v4 << v5 << v6}}

      g_ids = ImageServerGroup.where(:id=>{'$in'=>image_group_id.values.uniq}).pluck(:id, :group_name)
      group_name = Hash.new{|h,k| h[k]=[]}.tap{|h| g_ids.each{|k,v| h[k] = v}}

      assignment, count = generate_assignment_for_parse(assignment_id,userid,group_name,image_group_id,image_assignment_id,image)

      return assignment, count
    end

    def filter_assignments_by_userid(user_id,syndicate,image_server_group_id)
      if user_id.nil?
        u_ids = UseridDetail.where(:syndicate=>syndicate, :active=>true).pluck(:id,:userid)
        syndicate_id = Syndicate.where(:syndicate_code=>syndicate).first
        a_ids = Assignment.where(:syndicate=>syndicate_id.id).pluck(:id, :source_id, :assign_date, :instructions, :userid_detail_id)
      else
        u_ids = UseridDetail.where(:id=>{'$in'=>user_id}, :active=>true).pluck(:id,:userid)
        a_ids = Assignment.where(:userid_detail_id=>{'$in'=>user_id}).pluck(:id, :source_id, :assign_date, :instructions, :userid_detail_id)
      end

      userid = Hash.new{|h,k| h[k]=[]}.tap{|h| u_ids.each{|k,v| h[k] = v}}
      assignment_id = Hash.new{|h,k| h[k]=[]}.tap{|h| a_ids.each{|k,v1,v2,v3,v4| h[k] << v1 << v2 << v3 << v4}}

      i_ids = ImageServerImage.where(:assignment_id=>{'$in'=>a_ids.map(&:first)}).pluck(:id, :assignment_id, :image_server_group_id, :image_file_name, :status, :difficulty, :notes)
      image_assignment_id = Hash.new{|h,k| h[k]=[]}.tap{|h| i_ids.each{|k,v1,v2| h[k] = v1}}
      image_group_id = Hash.new{|h,k| h[k]=[]}.tap{|h| i_ids.each{|k,v1,v2,v3| h[k] = v2}}
      image = Hash.new{|h,k| h[k]=[]}.tap{|h| i_ids.each{|k,v1,v2,v3,v4,v5,v6| h[k] << v3 << v4 << v5 << v6}}

      g_ids = ImageServerGroup.where(:id=>{'$in'=>image_group_id.values.uniq}).pluck(:id, :group_name)
      group_name = Hash.new{|h,k| h[k]=[]}.tap{|h| g_ids.each{|k,v| h[k] = v}}

      assignment, count = generate_assignment_for_parse(assignment_id,userid,group_name,image_group_id,image_assignment_id,image)

      return assignment, count
    end

    def generate_assignment_for_parse(a_id,userid,group_name,image_group_id,image_assignment_id,image)
      assignment = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
      count = Hash.new

      image_assignment_id.each do |image_id,assignment_id|
        group_id = image_group_id[image_id]

        assignment[assignment_id][group_id][image_id][:id] = assignment_id
        assignment[assignment_id][group_id][image_id][:source_id] = a_id[assignment_id][0]
        assignment[assignment_id][group_id][image_id][:instructions] = a_id[assignment_id][2]
        assignment[assignment_id][group_id][image_id][:assign_date] = a_id[assignment_id][1]
        assignment[assignment_id][group_id][image_id][:userid] = userid[a_id[assignment_id][3]]
        assignment[assignment_id][group_id][image_id][:group_id] = group_id
        assignment[assignment_id][group_id][image_id][:group_name] = group_name[group_id]
        assignment[assignment_id][group_id][image_id][:image_id] = image_id
        assignment[assignment_id][group_id][image_id][:image_file_name] = image[image_id][0]
        assignment[assignment_id][group_id][image_id][:status] = image[image_id][1]
        assignment[assignment_id][group_id][image_id][:difficulty] = image[image_id][2]
        assignment[assignment_id][group_id][image_id][:notes] = image[image_id][3]
      end

      image_assignment_id.each {|k,v| count[v] = count[v].nil? ? 1 : count[v] + 1}

      return assignment, count
    end

    def get_image_detail(image_id)
      image = ImageServerImage.collection.aggregate([
                {'$match'=>{"_id"=>image_id}},
                {'$lookup'=>{from: "image_server_groups", localField: "image_server_group_id", foreignField: "_id", as: "image_group"}}, 
                {'$unwind'=>"$image_group"}
             ]).first

      return image
    end

   def id(id)
      where(:id => id)
    end

    def list_assignment_by_status(syndicate,status)
      image_server_group = ImageServerGroup.where(:syndicate_code=>syndicate).pluck(:id, :group_name)
      group_id = image_server_group.map{|a| a[0]}.uniq

      u_ids = UseridDetail.where(:syndicate=>syndicate).pluck(:id,:userid)
      userid = Hash.new{|h,k| h[k]=[]}.tap{|h| u_ids.each{|k,v| h[k] = v}}

      a_ids = Assignment.pluck(:id, :source_id, :assign_date, :instructions, :userid_detail_id)
      assignment_id = Hash.new{|h,k| h[k]=[]}.tap{|h| a_ids.each{|k,v1,v2,v3,v4| h[k] << v1 << v2 << v3 << v4}}

      i_ids = ImageServerImage.where(:assignment_id=>{'$in'=>a_ids.map(&:first)}, :status=>status, :image_server_group_id=>{'$in'=>group_id}).pluck(:id, :assignment_id, :image_server_group_id, :image_file_name, :status, :difficulty, :notes)
      image_assignment_id = Hash.new{|h,k| h[k]=[]}.tap{|h| i_ids.each{|k,v1,v2| h[k] = v1}}
      image_group_id = Hash.new{|h,k| h[k]=[]}.tap{|h| i_ids.each{|k,v1,v2,v3| h[k] = v2}}
      image = Hash.new{|h,k| h[k]=[]}.tap{|h| i_ids.each{|k,v1,v2,v3,v4,v5,v6| h[k] << v3 << v4 << v5 << v6}}

      g_ids = ImageServerGroup.where(:id=>{'$in'=>image_group_id.values.uniq}).pluck(:id, :group_name)
      group_name = Hash.new{|h,k| h[k]=[]}.tap{|h| g_ids.each{|k,v| h[k] = v}}

      assignment, count = generate_assignment_for_parse(assignment_id,userid,group_name,image_group_id,image_assignment_id,image)

      return assignment, count
    end

    def source_id(id)
      where(:source_id=>id)
    end

    def assign_image_server_image_to_assignment(assignment_id,user,image_list,image_status)
      assignment = Assignment.id(assignment_id).first

      if image_status.nil?
        ImageServerImage.where(:id=>{'$in'=>image_list}).update_all(:assignment_id=>assignment.id, :transcriber=>[user.userid])
      else
        case image_status
          when 'bt'
            ImageServerImage.where(:id=>{'$in'=>image_list}).update_all(:assignment_id=>assignment.id, :status=>image_status, :transcriber=>[user.userid])
          when 'br'
            ImageServerImage.where(:id=>{'$in'=>image_list}).update_all(:assignment_id=>assignment.id, :status=>image_status, :reviewer=>[user.userid])
        end
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

    def update_prev_assignment(assignment_id)
      prev_assignment_image_count = ImageServerImage.where(:assignment_id=>assignment_id).first

      Assignment.id(assignment_id).destroy if prev_assignment_image_count.nil?
    end

    def user_id(id)
      where(:userid_detail_id=>id)
    end

  end
end
