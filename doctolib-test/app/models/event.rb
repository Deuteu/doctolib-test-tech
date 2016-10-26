class Event < ActiveRecord::Base
  validates :kind, :inclusion  => { :in => [ 'opening', 'appointment' ], :message    => "%{value} is not a valid kind" }
  validate :startBeforeEnd
  validate :halfHour
  #Enum could be use but need to change :kind type in database

  HOUR_FORMAT = '%-k:%M'.freeze
  SLOT_DURATION = 30.minutes

  def self.availabilities(date = DateTime.now)
    #Should be good not to request day by day
    #cause some events are used twice (on different days) if on several daays
    #in particular weeklyEvents
    result = []
    for i in (0..6)
      d = date + i.days
      result.push({date: d.to_date, slots: self.dayAvailabilities(d)})
    end
    return result
  end

  #Less database call
  #15sec vs 20sec on test
  def self.alternateAvailabilities(date)
    #Init
    result = []
    weekStart = date.beginning_of_day
    weekEnd = (date + 6.days).end_of_day

    for i in (0..6)
      d = date + i.days
      result.push({date: d.to_date, slots: []})
    end

    #No recurring openings
    daylyOpenings = Event.where("starts_at < ?", weekEnd.utc).where("? < ends_at", weekStart.utc).where(weekly_recurring: nil, kind: "opening")
    for event in daylyOpenings
      #Take beginning of the event or the beginning of the week if starts before
      slot = [event.starts_at, weekStart].max
      #Stop at the end of the event or the end of the week if ends the after
      while slot < [event.ends_at, weekEnd].min
        i = result.index{|day| day[:date] === slot.to_date}
        result[i][:slots] << slot.strftime(HOUR_FORMAT)
        slot = (slot + SLOT_DURATION)
      end
    end
    
    
    #Recurring openings
    weeklyOpenings = Event.where("starts_at < ?", date.end_of_day.utc).where(weekly_recurring: true, kind: "opening")
    for event in weeklyOpenings
      slot = event.starts_at
      while slot < event.ends_at
        i = result.index{|day| day[:date].wday == slot.wday}
        result[i][:slots] << slot.strftime(HOUR_FORMAT)
        slot = (slot + SLOT_DURATION)
      end
    end

    #No recurring appointments
    daylyAppointments = Event.where("starts_at < ?", weekEnd.utc).where("? < ends_at", weekStart.utc).where(weekly_recurring: nil, kind: "appointment")
    for event in daylyAppointments
      #Take beginning of the event or the beginning of the week if starts before
      slot = [event.starts_at, weekStart].max
      #Stop at the end of the event or the end of the week if ends the after
      while slot < [event.ends_at, weekEnd].min
        i = result.index{|day| day[:date] === slot.to_date}
        result[i][:slots].delete slot.strftime(HOUR_FORMAT)
        slot = (slot + SLOT_DURATION)
      end
    end
    
    
    #Recurring appointments
    weeklyAppointments = Event.where("starts_at < ?", date.end_of_day.utc).where(weekly_recurring: true, kind: "appointment")
    for event in weeklyAppointments
      slot = event.starts_at
      while slot < event.ends_at
        i = result.index{|day| day[:date].wday == slot.wday}
        result[i][:slots].delete slot.strftime(HOUR_FORMAT)
        slot = (slot + SLOT_DURATION)
      end
    end
    result
  end


  def self.dayAvailabilities(date = DateTime.now)
    openings = dayAvailabilitiesKind(date, "opening").uniq
    appointments = dayAvailabilitiesKind(date, "appointment").uniq
    (openings - appointments).sort_by(&:to_i)
  end

  private
    def self.dayAvailabilitiesKind(date, kind)
      availabilities = []
      #Availabilities from non recurring events
      daylyEvents = Event.where("starts_at < ?", date.end_of_day.utc).where("? < ends_at", date.beginning_of_day.utc).where(weekly_recurring: nil, kind: kind)
      for event in daylyEvents
        #Take beginning of the event or the beginning of the day if starts the day before
        slot = [event.starts_at, date.beginning_of_day].max
        #Stop at the end of the event or the end of the day if ends the day after
        while slot < [event.ends_at, date.end_of_day].min
          availabilities.push(slot.strftime(HOUR_FORMAT))
          slot = (slot + SLOT_DURATION)
        end
      end
      #Availabilities from recurring event (only past ones)
      weeklyEvents = Event.where("starts_at < ?", date.end_of_day.utc).where(weekly_recurring: true, kind: kind)
      for event in weeklyEvents
        #Containing this day of week
        sameWeek = event.starts_at.wday <= event.ends_at.wday && event.starts_at.wday <= date.wday && date.wday <= event.ends_at.wday
        overTwoWeek = event.starts_at.wday > event.ends_at.wday && (event.starts_at.wday <= date.wday || date.wday <= event.ends_at.wday)
        if (sameWeek || overTwoWeek)
          #Take beginning of the eveny or the beginning of the day if starts the day before
          slot = (event.starts_at.wday == date.wday) ? date.change({hour: event.starts_at.hour, min: event.starts_at.min}) : date.beginning_of_day
          limit = (event.ends_at.wday == date.wday) ? date.change({hour: event.ends_at.hour, min: event.ends_at.min}) : date.end_of_day
          while slot < limit
            availabilities.push(slot.strftime(HOUR_FORMAT))
            slot = (slot + SLOT_DURATION)
          end
        end
      end
      availabilities
    end

    def halfHour
      if self.starts_at != roundDown(self.starts_at)
        errors.add(:starts_at, 'Starts_at must be an hour (eg: 12h00) or half hour (eg: 12h30)')
      end
      if self.ends_at != roundDown(self.ends_at)
        errors.add(:ends_at, 'Ends_at must be an hour (eg: 12h00) or half hour (eg: 12h30)')
      end
    end

    def startBeforeEnd
      if self.ends_at <= self.starts_at
        errors.add(:ends_at, 'Ends_at datetime must be after starts_at')
      end
    end

    def roundDown(date = DateTime.now)
      #find previous half hour
      oClock = date.beginning_of_hour
      half = oClock.change({min: 30})
      if (date < half)
        return oClock
      else
        return half
      end
    end
end