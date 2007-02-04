
class MainController < ApplicationController

  def index
    if user? 
      redirect_to :controller=>'news',:action=>'index'
    else
      redirect_to '/content/index'
    end
  end

end
