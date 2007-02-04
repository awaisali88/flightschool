require File.dirname(__FILE__) + '/../test_helper'
require 'schedule_mailer'

class ScheduleMailerTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
  end

  def test_reminder
    @expected.subject = 'ScheduleMailer#reminder'
    @expected.body    = read_fixture('reminder')
    @expected.date    = Time.now

    assert_equal @expected.encoded, ScheduleMailer.create_reminder(@expected.date).encoded
  end

  def test_reschedule
    @expected.subject = 'ScheduleMailer#reschedule'
    @expected.body    = read_fixture('reschedule')
    @expected.date    = Time.now

    assert_equal @expected.encoded, ScheduleMailer.create_reschedule(@expected.date).encoded
  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/schedule_mailer/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
