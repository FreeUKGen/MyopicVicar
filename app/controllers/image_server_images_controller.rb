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
    @group_name = ImageServerImage.get_sorted_group_name(image_server_group.source_id)

    if @image_server_image.nil?
      flash[:notice] = 'Attempted to edit a non_esxistent image file'
      redirect_to :back
    end
  end

  def flush
    display_info
    get_userids_and_transcribers or return

    @image_server_image = ImageServerImage.image_server_group_id(params[:id]).first
    @images = ImageServerImage.get_image_list(params[:id])
    @propagate_choice = params[:propagate_choice]

    if @image_server_image.nil?
      flash[:notice] = 'Attempted to edit a non_esxistent image file'
      redirect_to :back
    end
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
    session[:image_server_group_id] = params[:id]
    display_info

    @image_server_image = ImageServerImage.image_server_group_id(params[:id])
    @image_server_group = ImageServerGroup.id(session[:image_server_group_id]).first

    if @image_server_image.empty?
      flash[:notice] = 'No Images under Image Group "'+@image_server_group.group_name.to_s+'"'
      redirect_to index_image_server_group_path(@image_server_group.source)
    end
  end

  def move
    display_info
    get_userids_and_transcribers or return

    @image_server_group = ImageServerGroup.id(params[:id]).first
    @group_name = ImageServerImage.get_sorted_group_name(@image_server_group[:source_id])

    @image_server_image = ImageServerImage.image_server_group_id(params[:id]).first
    @images = ImageServerImage.get_image_list(params[:id])

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
    display_info
    @image = ImageServerImage.collection.aggregate([
                {'$match'=>{"_id"=>BSON::ObjectId.from_string(params[:id])}},
                {'$lookup'=>{from: "image_server_groups", localField: "image_server_group_id", foreignField: "_id", as: "image_group"}}, 
                {'$unwind'=>"$image_group"}
             ]).first
  end

  def update
    src_image_server_group = ImageServerGroup.id(image_server_image_params[:orig_image_server_group_id])
    src_image_server_image = ImageServerImage.where(
            :image_server_group_id=>image_server_image_params[:orig_image_server_group_id])

    image_server_group = ImageServerGroup.id(image_server_image_params[:image_server_group_id])
    image_server_image = ImageServerImage.where(
            :image_server_group_id=>image_server_image_params[:image_server_group_id])

    if image_server_image.nil?
      flash[:notice] = 'Image "'+image_server_image_params[:image_name]+'_'+image_server_image_params[:seq].to_s+'.jpg" does not exist'
      redirect_to :back
    else
      case image_server_image_params[:origin]
        when 'edit'
          edit_image = src_image_server_image.where(:seq=>image_server_image_params[:seq]).first
          image_server_image_params.delete :orig_image_server_group_id
          image_server_image_params.delete :origin

          edit_image.update_attributes(image_server_image_params)

          src_image_server_image.refresh_src_dest_group_summary(src_image_server_group)
          image_server_image.refresh_src_dest_group_summary(image_server_group)

          redirect_to image_server_image_path(edit_image) and return
        when 'move'
          image_server_image.where(
                :id=>{'$in': image_server_image_params[:seq]}, 
                :image_server_group_id=>image_server_image_params[:orig_image_server_group_id])
              .update_all(
                :image_server_group_id=>image_server_image_params[:image_server_group_id])

          src_image_server_image.refresh_src_dest_group_summary(src_image_server_group)
          image_server_image.refresh_src_dest_group_summary(image_server_group)

        when 'propagate_difficulty'
          image_server_image.where(
                :id=>{'$in': image_server_image_params[:seq]}, 
                :image_server_group_id=>image_server_image_params[:image_server_group_id])
              .update_all(:difficulty=>image_server_image_params[:difficulty])

          image_server_image.refresh_src_dest_group_summary(image_server_group)

        when 'propagate_status'
          image_server_image.where(
                :id=>{'$in': image_server_image_params[:seq]}, 
                :image_server_group_id=>image_server_image_params[:image_server_group_id])
              .update_all(:status=>image_server_image_params[:status])

          image_server_image.refresh_src_dest_group_summary(image_server_group)

        when 'propagate_transcriber'
          image_server_image.where(
                :id=>{'$in': image_server_image_params[:seq]}, 
                :image_server_group_id=>image_server_image_params[:image_server_group_id])
              .update_all(:transcriber=>image_server_image_params[:transcriber])

          image_server_image.refresh_src_dest_group_summary(image_server_group)

        when 'propagate_reviewer'
          image_server_image.where(
                :id=>{'$in': image_server_image_params[:seq]}, 
                :image_server_group_id=>image_server_image_params[:image_server_group_id])
              .update_all(:reviewer=>image_server_image_params[:reviewer])

          image_server_image.refresh_src_dest_group_summary(image_server_group)

        else
          flash[:notice] = 'Something wrong at ImageServerImage#update, please contact developer'
          redirect_to :back and return
      end
      flash[:notice] = 'Update of the Image file(s) was successful'
      redirect_to index_image_server_image_path(image_server_group.first)
    end
  end

  private
  def image_server_image_params
    params.require(:image_server_image).permit!
  end

end
