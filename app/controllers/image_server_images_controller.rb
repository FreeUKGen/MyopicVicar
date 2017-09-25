class ImageServerImagesController < ApplicationController
  require 'userid_role'
 
  skip_before_filter :require_login, only: [:show]

  def destroy
    display_info
    get_userids_and_transcribers or return

    image_server_image = ImageServerImage.where(:id=>params[:id]).first
    return_location = image_server_image.image_server_group
    image_server_image.destroy

    flash[:notice] = 'Deletion of image"'+image_server_image[:image_name]+'_'+image_server_image[:seq]+'.jpg" was successful'
    redirect_to image_server_image_path(return_location)
  end

  def detail
    display_info
    @image = ImageServerImage.collection.aggregate([
                {'$match'=>{"_id"=>BSON::ObjectId.from_string(params[:id])}},
                {'$lookup'=>{from: "image_server_groups", localField: "image_server_group_id", foreignField: "_id", as: "image_group"}}, 
                {'$unwind'=>"$image_group"}
             ]).first
  end

  def display_info
    @register = Register.find(:id=>session[:register_id])
    @register_type = RegisterType.display_name(@register.register_type)
    @church = Church.find(session[:church_id])
    @church_name = session[:church_name]
    @county =  session[:county]
    @place_name = session[:place_name]
    @place = @church.place #id?
    @county =  @place.county
    @place_name = @place.place_name
    @user = cookies.signed[:userid]
    @source = Source.find(:id=>session[:source_id])
    @group = ImageServerGroup.find(:id=>session[:image_server_group_id])
  end

  def edit
    display_info
    get_userids_and_transcribers or return

    @image_server_image = ImageServerImage.id(params[:id]).first
    image_server_group = @image_server_image.image_server_group
    get_sorted_group_name(image_server_group.source_id)

    if @image_server_image.nil?
      flash[:notice] = 'Attempted to edit a non_esxistent image file'
      redirect_to :back
    end
  end

  def flush
    display_info
    get_userids_and_transcribers or return

    get_image_list
    @propagate_choice = params[:propagate_choice]

    if @image_server_image.nil?
      flash[:notice] = 'Attempted to edit a non_esxistent image file'
      redirect_to :back
    end
  end

  def get_image_list
    @image_server_image = ImageServerImage.where(:image_server_group_id=>params[:id]).first
    seq = ImageServerImage.where(:image_server_group_id=>params[:id]).pluck(:seq, :image_name)

    myseq = Hash.new{|h,k| h[k] = []}
    @images = Hash[seq.map {|k,v| [k1 = v.to_s+':'+k.to_s, myseq[k] = v.to_s+'_'+k.to_s]}]   #get new hash key=image_name:seq, val=image_name_seq
  end

  def get_sorted_group_name(source_id)    # get hash key=image_server_group_id, val=ig, sorted by ig
    ig_array = ImageServerGroup.where(:source_id=>source_id).pluck(:id, :group_name)
    @group_name = Hash[ig_array.map {|key,value| [key,value]}]
    @group_name = @group_name.sort_by{|key,value| value.downcase}.to_h
  end

  def get_userids_and_transcribers
    @user = cookies.signed[:userid]
    @first_name = @user.person_forename unless @user.blank?

    case @user.person_role
      when 'system_administrator', 'country_coordinator', 'data_manager'
        @userids = UseridDetail.where(:active=>true).order_by(userid_lower_case: 1)
      when 'county_coordinator'
        @userids = UseridDetail.where(:syndicate => @user.syndicate, :active=>true).all.order_by(userid_lower_case: 1) # need to add ability for more than one syndicate
      else
        flash[:notice] = 'Your account does not support this action'
        redirect_to :back and return
      end

    @people =Array.new
    @userids.each do |ids|
      @people << ids.userid
    end
  end

  def index
    @is_image = IsImage.where(:source_id => @source_id).all.order_by(group_name: 1)
  end

  def move
    display_info
    get_userids_and_transcribers or return

    @image_server_group = ImageServerGroup.id(params[:id]).first
    get_sorted_group_name(@image_server_group[:source_id])

    get_image_list

    if @image_server_image.nil?
      flash[:notice] = 'Attempted to edit a non_esxistent image file'
      redirect_to :back
    end
  end

  def new      
    get_userids_and_transcribers or return

    @county =  session[:county]
    @place_name = session[:place_name]
    @church_name =  session[:church_name]
    @place = Place.find(session[:place_id])
    @church = Church.find(session[:church_id])
    @register = Register.new
  end

  def show
    session[:image_server_group_id] = params[:id]
    display_info

    @image_server_image = ImageServerImage.where(:image_server_group_id=>params[:id])
    @image_server_group = ImageServerGroup.where(:id=>session[:image_server_group_id]).first

    if @image_server_image.empty?
      flash[:notice] = 'No Images under Image Group "'+@image_server_group.group_name.to_s+'"'
      redirect_to image_server_group_path(@image_server_group.source)
    end
  end

  def update
    case params[:image_server_image][:seq].class.to_s
      when 'String'         # from edit.html.erb
        file_name = params[:image_server_image][:image_name]
        file_seq = params[:image_server_image][:seq]

        file_hash = Hash.new{|h,k| h[k] = []}
        file_hash[file_name] = [file_seq]

      when 'Array'          # from move.html.erb or flush.html.erb
        file_array = []
        params[:image_server_image][:seq].each do |x|
          file_name = x.split(':')[0]
          file_seq = x.split(':')[1]
          file_array << [file_name, file_seq] 
        end
        file_hash = Hash.new{|h,k| h[k] = []}
        file_array.group_by(&:first).collect{|k,v| [k, file_hash[k] = v.collect{|v| v[1]}]}.to_h

      when 'NilClass'
        flash[:notice] = 'Please choose an image you want to make change'
        redirect_to :back and return
    end

    src_image_server_group = ImageServerGroup.where(:id=>params[:image_server_image][:orig_image_server_group_id])
    src_image_server_image = ImageServerImage.where(:image_server_group_id=>params[:image_server_image][:orig_image_server_group_id])

    image_server_group = ImageServerGroup.where(:id=>params[:image_server_image][:image_server_group_id])
    image_server_image = ImageServerImage.where(:image_server_group_id=>params[:image_server_image][:image_server_group_id])

    if image_server_image.nil?
      flash[:notice] = 'Image "'+params[:image_server_image][:image_name]+'_'+params[:image_server_image][:seq].to_s+'.jpg" does not exist'
      redirect_to :back
    else
      case params[:image_server_image][:origin]
        when 'edit'
          params[:image_server_image].delete :orig_image_server_group_id
          params[:image_server_image].delete :origin

          src_image_server_image.first.update_attributes(image_server_image_params)

          src_image_server_image.refresh_src_dest_group_summary(src_image_server_group)
          image_server_image.refresh_src_dest_group_summary(image_server_group)

        when 'move'
          file_hash.each do |file_name,file_seq|
            image_server_image.where(:image_server_group_id=>image_server_image_params[:orig_image_server_group_id], :image_name=>file_name, :seq=>{'$in':file_seq}).update_all(:image_server_group_id=>image_server_image_params[:image_server_group_id])
          end

          src_image_server_image.refresh_src_dest_group_summary(src_image_server_group)
          image_server_image.refresh_src_dest_group_summary(image_server_group)

        when 'propagate_difficulty'
          file_hash.each do |file_name,file_seq|
            image_server_image.where(:image_server_group_id=>params[:image_server_image][:image_server_group_id], :image_name=>file_name, :seq=>{'$in':file_seq}).update_all(:difficulty=>params[:image_server_image][:difficulty])
          end

          # update ImageServerGroup field summary[:difficulty]
          image_server_group.update_image_group_summary(0, params[:image_server_image][:difficulty], nil, nil, nil, nil)

        when 'propagate_status'
          file_hash.each do |file_name,file_seq|
            image_server_image.where(:image_server_group_id=>params[:image_server_image][:image_server_group_id], :image_name=>file_name, :seq=>{'$in':file_seq}).update_all(:status=>params[:image_server_image][:status])
          end

          # update ImageServerGroup field summary[:status]
          image_server_group.update_image_group_summary(0, nil, params[:image_server_image][:status], nil, nil, nil)

        when 'propagate_transcriber'
          file_hash.each do |file_name,file_seq|
            image_server_image.where(:image_server_group_id=>params[:image_server_image][:image_server_group_id], :image_name=>file_name, :seq=>{'$in':file_seq}).update_all(:transcriber=>params[:image_server_image][:transcriber])
          end

          # update ImageServerGroup field summary[:transcriber]
          image_server_group.update_image_group_summary(0, nil, nil, params[:image_server_image][:transcriber], nil, nil)

        when 'propagate_reviewer'
          file_hash.each do |file_name,file_seq|
            image_server_image.where(:image_server_group_id=>params[:image_server_image][:image_server_group_id], :image_name=>file_name, :seq=>{'$in':file_seq}).update_all(:reviewer=>params[:image_server_image][:reviewer])
          end

          # update ImageServerGroup field summary[:reviewer]
          image_server_group.update_image_group_summary(0, nil, nil, nil, params[:image_server_image][:reviewer], nil)

        else
          flash[:notice] = 'Something wrong at ImageServerImage#update, please contact developer'
          redirect_to :back and return
      end
      flash[:notice] = 'Update of the Image file(s) was successful'
      redirect_to image_server_image_path(image_server_group.first)
    end
  end

  private
  def image_server_image_params
    params.require(:image_server_image).permit!
  end

end
