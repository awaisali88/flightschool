class SchedulingAccessRule < ReservationRule

  # returns list of violated schedule access rules for a user
  def self.violated_access_rules user
    rules = SchedulingAccessRule.find_all()
    violated_rules = []
    exceptions = ReservationRulesException.find_all_by_user_id(user.id).map{|e| e.reservation_rule_id}
    rules.each{|rule|
      if exceptions.include? rule.id.to_i 
        next
      end

      case rule.name
      when 'approved_user':
        groups = user.approved_groups.map{|g| g.group_name}
        if not (groups.include? 'admin' or groups.include? 'instructor' or groups.include? 'renter' or groups.include? 'student')
          violated_rules<<rule 
        end
      when 'has_contact_info':
        if user.phone_numbers.size==0 
          violated_rules<<rule 
        end
      end
    } 
    return violated_rules
  end
  
end