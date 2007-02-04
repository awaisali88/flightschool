##############################################################################
#
# Module with methods for sending out notification emails related to the
# scheduling system. The methods are called from external scripts (cron jobs)
#
# Authors:: Lev Popov levpopov@mit.edu
#
##############################################################################

module ScheduleReminders

  # send reminder emails to users with upcoming reservations
  def self.send_reminders
    from = (Time.now.to_date+1).to_time
    to = (from.to_date+1).to_time
    @reservations = Reservation.find(:all,:conditions=>["time_start>? and time_start<? and status='approved' and reservation_type='booking'",from,to],:include=>[:creator])
    @users = {}
    @reservations.each{|r|
      @users[r.created_by] ||= []
      @users[r.created_by] << r
    }
    @users.each{|u_id,rs|
      ScheduleMailer.deliver_reminder rs[0].creator,rs
    }
  end
  
  # send emails to pilots and instructors whose reservations have been modified
  def self.send_change_notices
    @reservations = Reservation.changed_reservations
    @users = {} #users with reservation changes
    @instructors = {} #instructors with reservation changes
    @reservations.each{|r|
      a = r.attributes_before_type_cast
      if a["o_status"] != a["status"] || 
         a["pilot"] != a["created_by"] ||
         a["instructor"] != a["instructor_id"] ||
         a["aircraft"] != a["aircraft_id"] ||
         a["from"] != a["time_start"] ||
         a["to"] != a["time_end"]
         
         @users[r.created_by] ||= []
         @users[r.created_by] << r   
         if not r.instructor_id.nil?   
           @instructors[r.instructor_id] ||= []
           @instructors[r.instructor_id] << r      
         end
      end
    }
    @users.each{|u_id,rs|
      Reservation.transaction do
        rs.each{|r| r.reload}
        ScheduleMailer.deliver_reservation_changes rs[0].creator,rs
        rs.each{|r| r.connection.execute("update reservations_changes set sent = true where id=#{r.id}")}
      end
    }
    @instructors.each{|u_id,rs|
        # TODO: add a column in reservation_changes table to keep track of sent emails like the one for pilots?
        ScheduleMailer.deliver_instructor_reservation_changes rs[0].instructor,rs
    }
  end
end