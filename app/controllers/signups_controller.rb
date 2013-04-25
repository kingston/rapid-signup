class SignupsController < ApplicationController
  def sync
    if request.post? and request.POST.include? "data"
      data = ActiveSupport::JSON.decode(request.POST["data"])
      data.each do |item|
        signup = Signup.find_or_create_by_email(:email => item['email'])
        signup.name = item['name']
        signup.save!
      end
      respond_to do |format|
        format.html
        format.js { render :json => { :success => true } }
      end
    end
  end
end
