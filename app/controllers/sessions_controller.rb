# encoding: utf-8
class SessionsController < ApplicationController

  def delete
    CASClient::Frameworks::Rails::Filter.logout(self)
  end

end