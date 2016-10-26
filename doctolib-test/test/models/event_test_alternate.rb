require 'test_helper'

class EventTest < ActiveSupport::TestCase
  test "one simple test example" do
    Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-04 09:30"), ends_at: DateTime.parse("2014-08-04 12:30"), weekly_recurring: true
    Event.create kind: 'appointment', starts_at: DateTime.parse("2014-08-11 10:30"), ends_at: DateTime.parse("2014-08-11 11:30")

    availabilities = Event.alternateAvailabilities DateTime.parse("2014-08-10")
    assert_equal Date.new(2014, 8, 10), availabilities[0][:date]
    assert_equal [], availabilities[0][:slots]
    assert_equal Date.new(2014, 8, 11), availabilities[1][:date]
    assert_equal ["9:30", "10:00", "11:30", "12:00"], availabilities[1][:slots]
    assert_equal Date.new(2014, 8, 16), availabilities[6][:date]
    assert_equal 7, availabilities.length
  end

  test "no opening" do
    availabilities = Event.alternateAvailabilities DateTime.parse("2014-08-10")
    assert_equal [], availabilities[0][:slots]
    assert_equal [], availabilities[1][:slots]
    assert_equal [], availabilities[2][:slots]
    assert_equal [], availabilities[3][:slots]
    assert_equal [], availabilities[4][:slots]
    assert_equal [], availabilities[5][:slots]
    assert_equal [], availabilities[6][:slots]
  end

  test "weekly opening starting after" do
    Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-10 09:30"), ends_at: DateTime.parse("2014-08-10 12:30"), weekly_recurring: true

    availabilities = Event.alternateAvailabilities DateTime.parse("2014-08-01")
    assert_equal [], availabilities[0][:slots]
    assert_equal [], availabilities[1][:slots]
    assert_equal [], availabilities[2][:slots]
    assert_equal [], availabilities[3][:slots]
    assert_equal [], availabilities[4][:slots]
    assert_equal [], availabilities[5][:slots]
    assert_equal [], availabilities[6][:slots]
  end

  test "single opening starting after" do
    Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-10 09:30"), ends_at: DateTime.parse("2014-08-10 12:30")

    availabilities = Event.alternateAvailabilities DateTime.parse("2014-08-01")
    assert_equal [], availabilities[0][:slots]
    assert_equal [], availabilities[1][:slots]
    assert_equal [], availabilities[2][:slots]
    assert_equal [], availabilities[3][:slots]
    assert_equal [], availabilities[4][:slots]
    assert_equal [], availabilities[5][:slots]
    assert_equal [], availabilities[6][:slots]
  end

  test "mix weekly and single openings" do
    Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-04 09:30"), ends_at: DateTime.parse("2014-08-04 12:30"), weekly_recurring: true
    Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-12 10:30"), ends_at: DateTime.parse("2014-08-12 12:30")

    availabilities = Event.alternateAvailabilities DateTime.parse("2014-08-10")
    assert_equal Date.new(2014, 8, 11), availabilities[1][:date]
    assert_equal ["9:30", "10:00", "10:30", "11:00", "11:30", "12:00"], availabilities[1][:slots]
    assert_equal Date.new(2014, 8, 12), availabilities[2][:date]
    assert_equal ["10:30", "11:00", "11:30", "12:00"], availabilities[2][:slots]
  end

  test "single opening on multiple days" do
    Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-11 22:30"), ends_at: DateTime.parse("2014-08-12 02:30")

    availabilities = Event.alternateAvailabilities DateTime.parse("2014-08-10")
    assert_equal Date.new(2014, 8, 11), availabilities[1][:date]
    assert_equal ["22:30", "23:00", "23:30"], availabilities[1][:slots]
    assert_equal Date.new(2014, 8, 12), availabilities[2][:date]
    assert_equal ["0:00", "0:30", "1:00", "1:30", "2:00"], availabilities[2][:slots]
  end

  test "weekly opening on multiple days" do
    Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-04 22:30"), ends_at: DateTime.parse("2014-08-05 02:30"), weekly_recurring: true

    availabilities = Event.alternateAvailabilities DateTime.parse("2014-08-10")
    assert_equal Date.new(2014, 8, 11), availabilities[1][:date]
    assert_equal ["22:30", "23:00", "23:30"], availabilities[1][:slots]
    assert_equal Date.new(2014, 8, 12), availabilities[2][:date]
    assert_equal ["0:00", "0:30", "1:00", "1:30", "2:00"], availabilities[2][:slots]
  end

  test "weekly opening on two week" do
    Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-01 22:30"), ends_at: DateTime.parse("2014-08-05 02:30"), weekly_recurring: true

    whole_day = ["0:00", "0:30", "1:00", "1:30", "2:00", "2:30", "3:00", "3:30", "4:00", "4:30", "5:00", "5:30", "6:00", "6:30", "7:00", "7:30", "8:00", "8:30", "9:00", "9:30", "10:00", "10:30", "11:00", "11:30", "12:00", "12:30", "13:00", "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30", "17:00", "17:30", "18:00", "18:30", "19:00", "19:30", "20:00", "20:30", "21:00", "21:30", "22:00", "22:30", "23:00", "23:30"] 
    
    availabilities = Event.alternateAvailabilities DateTime.parse("2014-08-08") #Saturday
    assert_equal Date.new(2014, 8, 8), availabilities[0][:date]
    assert_equal ["22:30", "23:00", "23:30"], availabilities[0][:slots]
    assert_equal Date.new(2014, 8, 9), availabilities[1][:date]
    assert_equal whole_day, availabilities[1][:slots]
    assert_equal Date.new(2014, 8, 10), availabilities[2][:date]
    assert_equal whole_day, availabilities[2][:slots]
    assert_equal Date.new(2014, 8, 11), availabilities[3][:date]
    assert_equal whole_day, availabilities[3][:slots]
    assert_equal Date.new(2014, 8, 12), availabilities[4][:date]
    assert_equal ["0:00", "0:30", "1:00", "1:30", "2:00"], availabilities[4][:slots]
    assert_equal Date.new(2014, 8, 13), availabilities[5][:date]
    assert_equal [], availabilities[5][:slots]
    assert_equal Date.new(2014, 8, 14), availabilities[6][:date]
    assert_equal [], availabilities[6][:slots]
  end
end
