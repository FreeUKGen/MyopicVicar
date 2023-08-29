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

    def assign_image_server_image_to_assignment(assignment_id,user,image_list,image_status)
      assignment = Assignment.id(assignment_id).first

      if image_status.nil?        # re-assign
        ImageServerImage.where(:id=>{'$in'=>image_list}).update_all(:assignment_id=>assignment.id, :transcriber=>[user.userid])
      else
        case image_status         # assign
        when 'bt'
            ImageServerImage.where(:id=>{'$in'=>image_list}).update_all(:assignment_id=>assignment.id, :status=>image_status, :transcriber=>[user.userid])
        when 'br'
            ImageServerImage.where(:id=>{'$in'=>image_list}).update_all(:assignment_id=>assignment.id, :status=>image_status, :reviewer=>[user.userid])
        end
      end
    end


    def bulk_update_assignment(my_own,assignment_id,action_type,orig_status,new_status)
      assignment = Assignment.id(assignment_id)
      return false if assignment.first.nil?

      image_server_image = ImageServerImage.where(:assignment_id=>assignment_id, :status=>orig_status)
      return false if image_server_image.first.nil? 

      image_server_group = ImageServerGroup.where(:id=>image_server_image.first.image_server_group.id)
      user = UseridDetail.where(:id=>assignment.first.userid_detail_id).first.userid

      if !my_own          # accept from SC
        assignment_list = assignment.pluck(:id)
        image_list = image_server_image.pluck(:id).map {|x| x.to_s}

        update_original_assignments(assignment_list,'',image_list)
      end

      update_image_server_image_to_update_assignment(image_server_image,assignment_id,action_type,new_status,user)

      ImageServerImage.refresh_src_dest_group_summary(image_server_group)

      return true
    end

    def bulk_update_assignments(my_own,assignment_ids,action_type,orig_status,new_status)
      if assignment_ids.kind_of?(Array)             # from 'Accept All Assignments' button
        assignment_ids.each do |x|
          @update_result = bulk_update_assignment(my_own,x,action_type,orig_status,new_status)

          if @update_result == true
            UserMailer.notify_sc_assignment_complete(assignment_id).deliver_now if my_own # from transcriber
          end
        end

        @update_result == true ? (return true) : (return false)
      else                  # from other update assginment status links
        update_result = bulk_update_assignment(my_own,assignment_ids,action_type,orig_status,new_status)

        if update_result == true
          UserMailer.notify_sc_assignment_complete(assignment_ids).deliver_now if my_own # from transcriber
        end

        update_result == true ? (return true) : (return false)
      end
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
      if a_ids.empty?
        assignment = nil
        count = nil
      else
        assignment_id = Hash.new{|h,k| h[k]=[]}.tap{|h| a_ids.each{|k,v1,v2,v3,v4| h[k] << v1 << v2 << v3 << v4}}

        u_ids = UseridDetail.where(:id=>a_ids[0][4]).pluck(:id,:userid)
        userid = Hash.new{|h,k| h[k]=[]}.tap{|h| u_ids.each{|k,v| h[k] = v}}

        i_ids = ImageServerImage.where(:assignment_id=>a_ids[0][0]).pluck(:id, :assignment_id, :image_server_group_id, :image_file_name, :status, :difficulty, :notes)

        (assignment_id, image_assignment_id, image_group_id, image, group_name) = prepare_for_parsing(a_ids,i_ids)

        assignment, count = generate_parsing_assignment(assignment_id,userid,group_name,image_group_id,image_assignment_id,image)
      end

      return assignment, count
    end

    def filter_assignments_by_userid(user_id,syndicate,image_server_group_id)
      if user_id.nil?
        syndicate_id = Syndicate.where(:syndicate_code=>syndicate).first
        a_ids = Assignment.where(:syndicate_id=>syndicate_id.id).pluck(:id, :source_id, :assign_date, :instructions, :userid_detail_id)
        u_ids = UseridDetail.where(:id=>{'$in'=>a_ids.map{|x| x[4]}}).pluck(:id,:userid)
      else
        u_ids = UseridDetail.where(:id=>{'$in'=>user_id}, :active=>true).pluck(:id,:userid)
        a_ids = Assignment.where(:userid_detail_id=>{'$in'=>user_id}).pluck(:id, :source_id, :assign_date, :instructions, :userid_detail_id)
      end

      userid = Hash.new{|h,k| h[k]=[]}.tap{|h| u_ids.each{|k,v| h[k] = v}}

      i_ids = ImageServerImage.where(:assignment_id=>{'$in'=>a_ids.map(&:first)}).pluck(:id, :assignment_id, :image_server_group_id, :image_file_name, :status, :difficulty, :notes)
      group_name = group_name.sort_by{ |k,v| v.scan(/\d+/).join('').to_i }

      (assignment_id, image_assignment_id, image_group_id, image, group_name) = prepare_for_parsing(a_ids,i_ids)

      assignment, count = generate_parsing_assignment(assignment_id,userid,group_name,image_group_id,image_assignment_id,image)

      return assignment, count
    end

    def generate_parsing_assignment(a_id,userid,group_name,image_group_id,image_assignment_id,image)
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

    def get_flash_message(type,my_own)
      case type
      when 'complete'
          if my_own then flash_message = 'email is sent to syndicate coordinator'  # from SC
                    else flash_message = 'Accept assignment was successful'        # from transcriber
          end
      when 'unassign'
          flash_message = 'UN_ASSIGN assignment was successful'
      end

      return flash_message
    end

    def get_group_id_for_list_assignment(params)
      if !params[:assignment].nil?      # from LIST
        group_id = get_group_id_for_list_request(params[:assignment][:image_server_group_id])
      else                              # from UPDATE
        group_id = get_group_id_for_update_request(params[:image_server_group_id])
      end

      return group_id
    end      

    def get_group_id_for_update_request(image_server_group_id)
      if image_server_group_id.nil?    # list assignment under a syndicate
        group_id = nil
      else                             # list assignments under a image group of a syndicate
        group_id = BSON::ObjectId.from_string(image_server_group_id)
      end

      return group_id
    end

    def get_group_id_for_list_request(image_server_group_id)
      if image_server_group_id.nil?            # update assignment under syndicate
        group_id = nil
      else                              # update assignment under image group of a syndicate
        group_id = BSON::ObjectId.from_string(image_server_group_id)
      end

      return group_id
    end

    def get_image_detail(image_id)
      image = ImageServerImage.collection.aggregate([
                {'$match'=>{"_id"=>image_id}},
                {'$lookup'=>{from: "image_server_groups", localField: "image_server_group_id", foreignField: "_id", as: "image_group"}}, 
                {'$unwind'=>"$image_group"}
             ]).first

      return image
    end

    def get_update_assignment_new_status(type,my_own,orig_status)
      case type
      when 'complete'
          if my_own then new_status = orig_status == 'bt' ? 'ts' : 'rs' # from SC
                    else new_status = orig_status == 'ts' ? 't' : 'r'   # from transcriber
          end
      when 'unassign'
          new_status = orig_status == 'bt' ? 'a' : 't'
      end

      return new_status
    end

    def get_reassign_list(type,transcriber_list,reviewer_list)
      case type
      when 'transcriber'
          reassign_list = transcriber_list.reject{|x| x.to_i == 0}
      when 'reviewer'
          reassign_list = reviewer_list.reject{|x| x.to_i == 0}
      end
    end

    def get_source_id(type,source_id,transcriber_list,reviewer_list)
      if source_id.nil?       # from list assignments under a syndicate
        if type == 'transcriber' then image_id = transcriber_list.reject{|x| x.to_i == 0}[0]
                                 else image_id = reviewer_list.reject{|x| x.to_i == 0}[0]
        end
        source_id = ImageServerImage.id(image_id).first.image_server_group.source.id
      end

      return source_id
    end

    def id(id)
      where(:id => id)
    end

    def list_assignment_by_status(syndicate,status)
      image_server_group = ImageServerGroup.where(:syndicate_code=>syndicate).pluck(:id, :group_name)
      group_id = image_server_group.map{|a| a[0]}.uniq

      u_ids = UseridDetail.pluck(:id,:userid)
      userid = Hash.new{|h,k| h[k]=[]}.tap{|h| u_ids.each{|k,v| h[k] = v}}

      a_ids = Assignment.pluck(:id, :source_id, :assign_date, :instructions, :userid_detail_id)

      i_ids = ImageServerImage.where(:assignment_id=>{'$in'=>a_ids.map(&:first)}, :status=>status, :image_server_group_id=>{'$in'=>group_id}).pluck(:id, :assignment_id, :image_server_group_id, :image_file_name, :status, :difficulty, :notes)

      (assignment_id, image_assignment_id, image_group_id, image, group_name) = prepare_for_parsing(a_ids,i_ids)

      assignment, count = generate_parsing_assignment(assignment_id,userid,group_name,image_group_id,image_assignment_id,image)

      return assignment, count
    end

    def prepare_for_parsing(a_ids,i_ids)
      assignment_id = Hash.new{|h,k| h[k]=[]}.tap{|h| a_ids.each{|k,v1,v2,v3,v4| h[k] << v1 << v2 << v3 << v4}}
      image_assignment_id = Hash.new{|h,k| h[k]=[]}.tap{|h| i_ids.each{|k,v1,v2| h[k] = v1}}
      image_group_id = Hash.new{|h,k| h[k]=[]}.tap{|h| i_ids.each{|k,v1,v2,v3| h[k] = v2}}
      image = Hash.new{|h,k| h[k]=[]}.tap{|h| i_ids.each{|k,v1,v2,v3,v4,v5,v6| h[k] << v3 << v4 << v5 << v6}}

      g_ids = ImageServerGroup.where(:id=>{'$in'=>image_group_id.values.uniq}).pluck(:id, :group_name)
      group_name = Hash.new{|h,k| h[k]=[]}.tap{|h| g_ids.each{|k,v| h[k] = v}}

      return assignment_id, image_assignment_id, image_group_id, image, group_name
    end

    def source_id(id)
      where(:source_id=>id)
    end

    def update_assignment_from_put_request(my_own,params)
      if params[:assignment_ids].nil?
        assignment_id = params[:id]                 # from 'AC' / 'CM' link
      else
        assignment_id = params[:assignment_ids]     # from 'Accept All Assignments' button
      end

      action_type = params[:type]
      orig_status = params[:status]
      assignment_list_type = params[:assignment_list_type]
      update_result = false

      new_status = get_update_assignment_new_status(action_type, my_own, orig_status)
      update_result = bulk_update_assignments(my_own,assignment_id,action_type,orig_status,new_status)

      update_result == true ? (return true) : (return false)
    end

    def update_assignment_from_reassign(params)
      assignment_id = params[:id]
      assign_type = params[:assignment][:type]
      instructions = params[:assignment][:instructions]
      transcriber_list = params[:assignment][:transcriber_image_file_name]
      reviewer_list = params[:assignment][:reviewer_image_file_name]
      source_id = params[:assignment][:source_id]
      user_id = params[:assignment][:user_id]
      image_server_group_id = params[:assignment][:image_server_group_id]

      source_id = get_source_id(assign_type,source_id,transcriber_list,reviewer_list)
      reassign_list = get_reassign_list(assign_type,transcriber_list,reviewer_list)
      user = UseridDetail.where(:userid=>{'$in'=>user_id}).first
      assignment = Assignment.id(params[:id])

      create_assignment(source_id,user,instructions,reassign_list,image_status=nil)
      update_prev_assignment(assignment_id)
      ImageServerImage.refresh_image_server_group_after_assignment(image_server_group_id)

      return true
    end

    def update_image_server_image_to_destroy_assignment(image_id,assign_type)
      image_status = assign_type == 'transcriber' ? 'a' : 't'

      image_server_image = ImageServerImage.id(image_id).first
      assignment = image_server_image.assignment
      assignment_id = image_server_image.assignment_id

      if assign_type == 'transcriber'
        image_server_image.update(:assignment_id=>nil, :transcriber=>[''], :status=>image_status)
      else
        image_server_image.update(:assignment_id=>nil, :reviewer=>[''], :status=>image_status)
      end
    end

    def update_image_server_image_to_update_assignment(image_server_image,assignment_id,action_type,new_status,user)
      case action_type
      when 'complete'
          case new_status
          when 'ts', 'rs'         # from transcriber
              image_server_image.where(:assignment_id=>assignment_id).update_all(:status=>new_status)
          when 't'                 # from SC
              image_server_image.update_all(:assignment_id=>nil, :status=>new_status, :transcriber=>[user])
          when 'r'                # from SC
              image_server_image.update_all(:assignment_id=>nil, :status=>new_status, :reviewer=>[user])
          end
      when 'unassign'
          case new_status
          when 'a'
              image_server_image.update_all(:assignment_id=>nil, :status=>new_status, :transcriber=>[''])
          when 't'
              image_server_image.update_all(:assignment_id=>nil, :status=>new_status, :reviewer=>[''])
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
