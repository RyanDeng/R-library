# encoding: utf-8
class UsersController < ApplicationController
  
  #before_action :signed_in_user, only: [:index]
  load_and_authorize_resource
  
  def index
    page = params[:page] || 1
    @users = User.search(params[:tag], page)
    respond_to do |format|
      format.html
    end
    
  end

  def show
    if current_user.has_admin_authe && params[:admin] == 'true'
      @admin_page = true
    end
    @user = User.find(params[:id])
    respond_to do |format|
      format.html 
    end
  end

  def edit
    @user = User.find(params[:id])
  end
  
  def update
    respond_to do |format|
      @user = User.find(params[:id])
      if current_user.super_admin?
        result = @user.update(admin_update_params)
      else
        result = @user.update(update_params)
      end
      if result
        flash[:success] = "更新成功!"
        format.html { redirect_to edit_user_path(@user.id) }
      else
        format.html {render action: "edit"}
      end
    
      
    end
    
  end
  
  def inactivate
    @admin_page = true
    respond_to do |format|
      @user = User.find(params[:id])
      if @user.update_attribute('status', :inactive)
        flash[:success] = '操作成功'  
      else
        flash[:error] = '操作失败!' << @user.errors.full_messages.to_s
      end
    
      format.html { render action: "show" }
    end
  end

  def activate
    @admin_page = true
    respond_to do |format|
      @user = User.find(params[:id])
      if @user.update_attribute('status', :active)
        flash[:success] = '操作成功'  
      else
        flash[:error] = '操作失败!' << @user.errors.full_messages.to_s
      end
    
      format.html { render action: "show" }
    end
  end
  
  def reset_passwd
    @user = User.find(params[:id])
  end

  def edit_passwd
    @user = User.find(params[:id])
  end

  def reset
    respond_to do |format|
      @user = User.find(params[:id])
      @user.password = params[:new_password]
      @user.password_confirmation = params[:confirm_password]
      if @user.save
        flash[:success] = '密码修改成功'
        format.html { redirect_to user_path(@user.id)}
      else
        format.html { render action: 'reset_passwd'}
      end  
    end
  end

  def update_passwd
    respond_to do |format|
      @user = User.find(params[:id])
      if @user.authenticate(params[:old_password])
        @user.password = params[:new_password]
        @user.password_confirmation = params[:confirm_password]
        if @user.save
          flash[:success] = '密码修改成功'
          format.html { redirect_to user_path(@user.id)}
        else
          format.html { render action: 'edit_passwd'}
        end
      else
        flash[:error] = '原密码错误'
        format.html { redirect_to action: 'edit_passwd'}
      end  
      
    end
  end
  
  private
    # Using a private method to encapsulate the permissible parameters is
    # just a good pattern since you'll be able to reuse the same permit
    # list between create and update. Also, you can specialize this method
    # with per-user checking of permissible attributes.
    def update_params
      params.require(:user).permit(:name,:team, :office)
    end

    def admin_update_params
      params.require(:user).permit(:role, :name, :team, :office)
    end

    def super_admin_create_params
      params.require(:user).permit(:name, :team, :email, :role, :office)
    end

    def create_params
      params.require(:user).permit(:name, :team, :email, :office)
    end
end
