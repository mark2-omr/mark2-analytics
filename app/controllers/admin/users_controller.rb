class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :admin_required
  before_action :set_user, only: %i[show edit update destroy]

  # GET /users or /users.json
  def index
    @group = Group.find(params[:group_id])

    if params[:q]
      query = User.where(group_id: params[:group_id])
      params[:q].split(/[[:blank:]]+/).each do |q|
        query = query.where('search_text like ?', "%#{q}%")
      end
      @users = query
    else
      @users = User.where(group_id: params[:group_id])
    end
    @users = @users.order('id ASC').page params[:page]
  end

  # GET /users/1 or /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new(group_id: params[:group_id])
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users or /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html do
          redirect_to admin_user_url(@user), notice: t('messages.user_created')
        end
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html do
          redirect_to admin_user_url(@user), notice: t('messages.user_updated')
        end
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    @user.destroy

    respond_to do |format|
      format.html do
        redirect_to admin_users_url(group_id: @user.group_id),
                    notice: t('messages.user_destroyed')
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def user_params
    params.require(:user).permit(:group_id, :email, :name, :admin, :manager)
  end
end
