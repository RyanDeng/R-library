# encoding: utf-8
module UserHelper

    def current_user=(user)
      @current_user = user
    end

    def current_user
    	@current_user
    end

    def signed_in?
      !current_user.nil? && current_user.name == session[:cas_user]
    end

    def signed_in_user
      ## make sure session[:cas_user] has been set value before this method invoked
      unless signed_in?
        user = User.find_by(email: session[:cas_user] + EMAIL_DOMAIN)
        if user.nil?
          if User.create(session[:cas_user])
            self.current_user = User.find_by(email: session[:cas_user] + EMAIL_DOMAIN)
          else
            redirect_to '/500.html'
          end
        else
          self.current_user = user
        end
      end
    end

    def sign_out
        self.current_user = nil
        cookies.delete(:remember_token)
    end

end
