class ImageServerImagesController < ApplicationController
  require 'userid_role'
 
  skip_before_filter :require_login, only: [:show]

  def destroy
    display_info
    image_server_image = ImageServerImage.where(:id=>params[:id]).first
    return_location = image_server_image.image_server_group
    image_server_image.destroy

    flash[:notice] = 'Deletion of image"'+image_server_image[:image_set]+'_'+image_server_image[:seq]+'.jpg" was successful'
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

    @image_server_image = ImageServerImage.id(params[:id]).first
    image_server_group = @image_server_image.image_server_group
    ig_array = ImageServerGroup.where(:source_id=>image_server_group.source_id).pluck(:id, :ig)
    @ig = Hash[ig_array.map {|key,value| [key,value]}]

    if @image_server_image.nil?
      flash[:notice] = 'Attempted to edit a non_esxistent image file'
      redirect_to :back
      return
    end
  end

  def index
    @is_image = IsImage.where(:source_id => @source_id).all.order_by(ig: 1)
  end

  def move
    display_info

    @image_server_group = ImageServerGroup.id(params[:id]).first
    ig_array = ImageServerGroup.where(:register_id=>@image_server_group[:register_id]).pluck(:id, :ig)
    @ig = Hash[ig_array.map {|key,value| [key,value]}]

    myseq = Hash.new{|h,k| h[k] = []}
    @image_server_image = ImageServerImage.where(:image_server_group_id=>params[:id]).first
    @test = ImageServerImage.where(:image_server_group_id=>params[:id])
    seq = ImageServerImage.where(:image_server_group_id=>params[:id]).pluck(:seq, :image_set)

    @images = Hash[seq.map {|k,v| [k, myseq[k] = v.to_s+'_'+k.to_s]}]

    if @image_server_image.nil?
      flash[:notice] = 'Attempted to edit a non_esxistent image file'
      redirect_to :back
      return
    end
  end

  def new      
    get_user_info_from_userid
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
    image_server_group = ImageServerGroup.where(:id=>session[:image_server_group_id]).first

    if @image_server_image.empty?
      flash[:notice] = 'No Images under Image Group "'+image_server_group.ig.to_s+'"'
      redirect_to image_server_group_path(image_server_group.source)
    else
      flash.clear
    end
  end

  def update
    image_server_image = ImageServerImage.where(:_id=>params[:image_server_image][:id]).first
    return_location = image_server_image.image_server_group
    image_server_group = ImageServerGroup.where(:id=>params[:image_server_image][:image_server_group_id]).first

    if image_server_image.present?
      image_server_image.update_attributes(image_server_image_params)

      if image_server_image.errors.any? then
        flash[:notice] = 'Update of the Image file was unsuccessful'
        redirect_to :back
      else
        flash[:notice] = 'Update of the Image file was successful'
        redirect_to image_server_image_path(image_server_group)
      end
    else
      flash[:notice] = 'Image "'+params[:image_server_image][:image_set]+'_'+params[:image_server_image][:image_set]+'.jpg" does not exist'
      redirect_to image_server_group_path(relocation_location)
      redirect_to :back
    end
  end

  private
  def image_server_image_params
    params.require(:image_server_image).permit!
  end

end
