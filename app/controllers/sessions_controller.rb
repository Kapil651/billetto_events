class SessionsController < ApplicationController
  def new
    redirect_to root_path if clerk.user?
  end

  def sign_up
    redirect_to root_path if clerk.user?
  end

  def destroy
  end
end
