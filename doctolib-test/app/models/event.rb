class Event < ActiveRecord::Base
  validates :kind, :inclusion  => { :in => [ 'opening', 'appointment' ], :message    => "%{value} is not a valid kind" }
  validate :startBeforeEnd
  validate :halfHour
  #Enum could be use but need to change :kind type in database

private

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