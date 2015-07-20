#encoding: utf-8
class ApplicationController < ActionController::Base
  include UserHelper
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter CASClient::Frameworks::Rails::Filter

  CASClient::Frameworks::Rails::Filter.fake("dengchao")

  before_action :signed_in_user

  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = '无权限访问此页面'
    redirect_to library_path
  end
  
end
