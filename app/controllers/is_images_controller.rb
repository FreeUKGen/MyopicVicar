class IsImagesController < ApplicationController
  require 'userid_role'
 
  skip_before_filter :require_login, only: [:show]

  def destroy
    is_image = IsImage.where(:is_source_id=>params[:id], :seq=>params[:seq]).first
    return_location = is_image.is_source
#    is_image.destroy

    flash[:notice] = 'Deletion of image"'+is_image[:image_set]+'_'+params[:seq]+'.jpg" was successful'
    redirect_to is_image_path(return_location)
  end

  def detail
    display_info
    @image = IsSource.collection.aggregate([
                {'$match'=>{"_id"=>BSON::ObjectId.from_string(params[:id])}},
                {'$lookup'=>{from: "is_images", localField: "_id", foreignField: "is_source_id", as: "image_list"}}, 
                {'$match'=>{"image_list.seq"=>params[:seq]}},
                {'$unwind'=>"$image_list"}
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
  end

  def edit
    display_info
    @is_source = IsSource.id(params[:id]).first
    @is_image = IsImage.where(:is_source_id=>params[:id], :seq=>params[:seq]).first
    ig = IsSource.where(:register_id=>@is_source[:register_id]).pluck(:id, :ig)
    @source_ig = Hash[ig.map {|key,value| [key,value]}]

    if @is_image.nil?
      flash[:notice] = 'Attempting to edit a non_esxistent image file'
      redirect_to :back
      return
    end
  end

  def index
    display_info
    @is_image = IsImage.where(:source_id => @source_id).all.order_by(ig: 1)
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
    if params[:register_id].nil?
      @is_source = IsSource.where(:id=>params[:id])
      source_id = @is_source.pluck(:id)
      ig = @is_source.first.ig
    else
      source_id = IsSource.where(:register_id=>params[:register_id]).pluck(:id)
    end

    @is_image = IsImage.where(:is_source_id=>{'$in'=>source_id})

#    @is_image = @is_source.is_image.all

    if @is_image.first.nil?
      flash[:notice] = 'No Image File under Image Group "'+ig.to_s+'"'
      redirect_to :back
    else
      get_user_info_from_userid
      display_info
      flash.clear
    end
  end

  def move
    display_info
    @is_source = IsSource.id(params[:id]).first
    ig = IsSource.where(:register_id=>@is_source[:register_id]).pluck(:id, :ig)
    @source_ig = Hash[ig.map {|key,value| [key,value]}]

    myseq = Hash.new{|h,k| h[k] = []}
    @is_image = IsImage.where(:is_source_id=>params[:id]).first
    @test = IsImage.where(:is_source_id=>params[:id])
    seq = IsImage.where(:is_source_id=>params[:id]).pluck(:seq, :image_set)

    @images = Hash[seq.map {|k,v| [k, myseq[k] = v.to_s+'_'+k.to_s]}]

    if @is_image.nil?
      flash[:notice] = 'Attempting to edit a non_esxistent image file'
      redirect_to :back
      return
    end
  end

  def update
p "========================is_image update======================"
    is_image = IsImage.where(:_id=>params[:is_image][:id]).first
    is_source = IsSource.where(:id=>params[:is_image][:is_source_id]).first

    if is_image.present?
      is_image.update_attributes(is_image_params)

      if is_image.errors.any? then
        flash[:notice] = 'Update of the Image file was unsuccessful'
        redirect_to :back
      else
        flash[:notice] = 'Update of the Image file was successful'
        redirect_to detail_is_image_path(:id=>params[:is_image][:is_source_id], :seq=>params[:is_image][:seq])
      end
    else
      flash[:notice] = 'something wrong'
      redirect_to is_source_path(is_source)
      redirect_to :back
    end
  end

  private
  def is_image_params
    params.require(:is_image).permit!
  end

end
