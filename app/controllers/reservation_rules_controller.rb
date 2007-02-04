class ReservationRulesController < ApplicationController
  def index
     return unless has_permission :can_edit_reservation_rules
     @page_title = 'Reservation Rules'
     @reservation_rules = ReservationRule.find(:all)
  end
  
  def exceptions
     return unless has_permission :can_edit_reservation_rules
      @user_id =  params[:user].nil? ? current_user.id : params[:user]
      @rule_exceptions = ReservationRulesException.find_all_by_user_id(@user_id,:order => 'id').map{|e|
        e.reservation_rule_id
      }
      @rules = ReservationRule.find(:all)
      @page_title = "Reservation Rules for "+User.find_by_id(@user_id).full_name
  end
  
  def update_exceptions
     return unless has_permission :can_edit_reservation_rules
    @rule_exceptions = ReservationRulesException.find_all_by_user_id(params[:user],:order => 'id')
    @rules = ReservationRule.find(:all).map{|r| r.id}
    ReservationRule.transaction do
      @rule_exceptions.each{|e|
        e.destroy
      }
      if ! params[:rules].nil?
          params[:rules].each_key{|rule_id|
            @rules.delete rule_id.to_i
          }
      end
      @rules.each{|rule_id|
            e = ReservationRulesException.new
            e.reservation_rule_id = rule_id
            e.user_id = params[:user]
            e.save
      }
    end
    redirect_to :action=>'exceptions',:controller=>'reservation_rules',:user=> params[:user]
  end
  
end
