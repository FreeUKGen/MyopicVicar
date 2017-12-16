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

      assignment.save
      source.assignments << assignment
      source.save
      userid_detail.assignments << assignment
      userid_detail.save

      assign_image_server_image_to_assignment(assignment.id,user_id,assign_list,image_status)
    end

    def filter_assignments_by_assignment_id(assignment_id)
        assignment = Assignment.collection.aggregate([
                {'$match'=>{"_id"=>BSON::ObjectId.from_string(assignment_id)}},
                {'$lookup'=>{from: "userid_details", localField: "userid_detail_id", foreignField: "_id", as:"userids"}},
                {'$lookup'=>{from: "image_server_images", localField: "_id", foreignField: "assignment_id", as: "images"}}, 
                {'$unwind'=>{'path'=>"$userids"}},
                {'$unwind'=>{'path'=>"$images"}}, 
                {'$lookup'=>{from: "image_server_groups", localField: 'images.image_server_group_id', foreignField: "_id", as: "groups"}},
                {'$unwind'=>{'path'=>"$groups"}},
                {'$project'=>{:fields=>'$$ROOT', 'lower_case_userid'=>{'$toLower'=>'userids.userid'}}},
                {'$sort'=>{'fields.assignment_finished'=>-1, 'lower_case_userid'=>1, 'fields.images.status'=>1}}
             ])

        group_by_count = Assignment.collection.aggregate([
                {'$match'=>{"_id"=>BSON::ObjectId.from_string(assignment_id)}},
                {'$lookup'=>{from: "userid_details", localField: "userid_detail_id", foreignField: "_id", as:"userids"}},
                {'$lookup'=>{from: "image_server_images", localField: "_id", foreignField: "assignment_id", as: "images"}}, 
                {'$unwind'=>{'path'=>"$userids"}},
                {'$unwind'=>{'path'=>"$images"}}, 
                {'$group'=>{_id:"$_id", total:{'$sum'=>1}}}
             ])

      count = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
      group_by_count.each do |x|
        count[x[:_id]] = x[:total]
      end

      return assignment, count
    end

    def filter_assignments_by_userid(user_ids,image_server_group_id)
      if image_server_group_id.nil?
        assignment = Assignment.collection.aggregate([
                {'$match'=>{"userid_detail_id"=>{'$in'=>user_ids}}},
                {'$lookup'=>{from: "userid_details", localField: "userid_detail_id", foreignField: "_id", as:"userids"}},
                {'$lookup'=>{from: "image_server_images", localField: "_id", foreignField: "assignment_id", as: "images"}}, 
                {'$unwind'=>{'path'=>"$userids"}},
                {'$unwind'=>{'path'=>"$images"}}, 
                {'$lookup'=>{from: "image_server_groups", localField: 'images.image_server_group_id', foreignField: "_id", as: "groups"}},
                {'$unwind'=>{'path'=>"$groups"}},
                {'$project'=>{:fields=>'$$ROOT', 'lower_case_userid'=>{'$toLower'=>'userids.userid'}}},
                {'$sort'=>{'fields.assignment_finished'=>-1, 'lower_case_userid'=>1, 'fields.images.status'=>1}}
             ])

        group_by_count = Assignment.collection.aggregate([
                {'$match'=>{"userid_detail_id"=>{'$in'=>user_ids}}},
                {'$lookup'=>{from: "userid_details", localField: "userid_detail_id", foreignField: "_id", as:"userids"}},
                {'$lookup'=>{from: "image_server_images", localField: "_id", foreignField: "assignment_id", as: "images"}}, 
                {'$unwind'=>{'path'=>"$userids"}},
                {'$unwind'=>{'path'=>"$images"}}, 
                {'$group'=>{_id:"$_id", total:{'$sum'=>1}}}
             ])
      else
        group_id = [image_server_group_id]
        assignment = Assignment.collection.aggregate([
                {'$lookup'=>{from: "image_server_images", localField: "_id", foreignField: "assignment_id", as: "images"}}, 
                {'$match'=>{"images.image_server_group_id"=>{'$in'=>group_id}}},
                {'$lookup'=>{from: "userid_details", localField: "userid_detail_id", foreignField: "_id", as:"userids"}},
                {'$match'=>{"userid_detail_id"=>{'$in'=>user_ids}}},
                {'$unwind'=>{'path'=>"$userids"}},
                {'$unwind'=>{'path'=>"$images"}}, 
                {'$lookup'=>{from: "image_server_groups", localField: 'images.image_server_group_id', foreignField: "_id", as: "groups"}},
                {'$unwind'=>{'path'=>"$groups"}},
                {'$project'=>{:fields=>'$$ROOT', 'lower_case_userid'=>{'$toLower'=>'userids.userid'}}},
                {'$sort'=>{'fields.assignment_finished'=>-1, 'lower_case_userid'=>1, 'fields.images.status'=>1}}
             ])

        group_by_count = Assignment.collection.aggregate([
                {'$lookup'=>{from: "image_server_images", localField: "_id", foreignField: "assignment_id", as: "images"}}, 
                {'$match'=>{"images.image_server_group_id"=>{'$in'=>group_id}}},
                {'$lookup'=>{from: "userid_details", localField: "userid_detail_id", foreignField: "_id", as:"userids"}},
                {'$match'=>{"userid_detail_id"=>{'$in'=>user_ids}}},
                {'$unwind'=>{'path'=>"$userids"}},
                {'$unwind'=>{'path'=>"$images"}}, 
                {'$group'=>{_id:"$_id", total:{'$sum'=>1}}}
             ])
      end          

      count = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
      group_by_count.each do |x|
        count[x[:_id]] = x[:total]
      end

      return assignment, count
    end

    def id(id)
      where(:id => id)
    end

    def list_assignment_by_status(syndicate,status)
      image_server_group = ImageServerGroup.where(:syndicate_code=>syndicate).pluck(:id, :group_name)
      group_id = image_server_group.map{|a| a[0]}.uniq

      assignment = Assignment.collection.aggregate([
                {'$lookup'=>{from: "image_server_images", localField: "_id", foreignField: "assignment_id", as: "images"}}, 
                {'$match'=>{"images.status"=>status, "images.image_server_group_id"=>{'$in'=>group_id}}},
                {'$lookup'=>{from: "userid_details", localField: "userid_detail_id", foreignField: "_id", as:"userids"}},
                {'$unwind'=>{'path'=>"$userids"}},
                {'$unwind'=>{'path'=>"$images"}}, 
                {'$lookup'=>{from: "image_server_groups", localField: 'images.image_server_group_id', foreignField: "_id", as: "groups"}},
                {'$unwind'=>{'path'=>"$groups"}},
                {'$project'=>{:fields=>'$$ROOT', 'lower_case_userid'=>{'$toLower'=>'userids.userid'}}},
                {'$sort'=>{'fields.assignment_finished'=>-1, 'lower_case_userid'=>1, 'fields.images.status'=>1}}
             ])

      group_by_count = Assignment.collection.aggregate([
                {'$lookup'=>{from: "image_server_images", localField: "_id", foreignField: "assignment_id", as: "images"}}, 
                {'$match'=>{"images.status"=>status, "images.image_server_group_id"=>{'$in'=>group_id}}},
                {'$lookup'=>{from: "userid_details", localField: "userid_detail_id", foreignField: "_id", as:"userids"}},
                {'$unwind'=>{'path'=>"$userids"}},
                {'$unwind'=>{'path'=>"$images"}}, 
                {'$group'=>{_id:"$_id", total:{'$sum'=>1}}}
             ])

      count = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
      group_by_count.each do |x|
        count[x[:_id]] = x[:total]
      end

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
