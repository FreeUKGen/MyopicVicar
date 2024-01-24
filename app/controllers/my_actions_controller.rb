class MyActionsController < ApplicationController
  before_action :set_my_action, only: [:show, :edit, :update, :destroy]

  # GET /my_actions
  def index
    @my_actions = MyAction.all
  end

  # GET /my_actions/1
  def show
  end

  # GET /my_actions/new
  def new
    @my_action = MyAction.new
  end

  # GET /my_actions/1/edit
  def edit
  end

  # POST /my_actions
  def create
    @my_action = MyAction.new(my_action_params)

    if @my_action.save
      redirect_to @my_action, notice: 'My action was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /my_actions/1
  def update
    if @my_action.update(my_action_params)
      redirect_to @my_action, notice: 'My action was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /my_actions/1
  def destroy
    @my_action.destroy
    redirect_to my_actions_url, notice: 'My action was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_my_action
      @my_action = MyAction.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def my_action_params
      params.require(:my_action).permit(:name, :description, :child_of)
    end
end
