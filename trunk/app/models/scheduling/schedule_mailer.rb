class ScheduleMailer < ActionMailer::Base

  # reminder email sent out to pilots with upcoming reservations 
  def reminder(user,reservations)
    setup_email(user)
    @subject    += ' Reservation Reminder'
    @body["name"] = user.full_name
    @body["reservations"] = reservations
  end

  # notification email sent to pilot whose reservation(s) have been altered
  def reservation_changes(user,reservations)
    setup_email(user)
    @subject    += ' Reservation(s) Updated'
    @body["name"] = user.full_name
    @body["reservations"] = reservations
  end
  
  # notification email sent to instructors whose reservation(s) have been altered
  def instructor_reservation_changes(instructor,reservations)
    setup_email(instructor)
    @subject    += ' Reservation(s) Updated'
    @body["name"] = instructor.full_name
    @body["reservations"] = reservations
  end
  
  # notification email sent to instructor when a pilot creates a reservation with him/her.
  def instructor_notification(user,reservation)
    setup_email(user)
    @subject    += 'New Reservation'
    @body["name"] = user.full_name
    @body["reservation"] = reservation
  end
  
  def setup_email(user)
    @recipients = "#{user.email}"
    @from       = LoginEngine.config(:email_from).to_s
    @subject    = "[#{LoginEngine.config(:app_name)}] "
    @sent_on    = Time.now
    @headers['Content-Type'] = "text/plain; charset=#{LoginEngine.config(:mail_charset)}; format=flowed"
  end
end
