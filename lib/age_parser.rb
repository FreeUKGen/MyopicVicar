class AgeParser
	YEAR_AGE_UNIT = ['y', 'year','years']
	MONTH_AGE_UNIT = ['m', 'month', 'months']
	WEEK_UNIT = ['w', 'week', 'weeks']
	DAY_UNIT = ['d', 'day', 'days']
	AGE_RANK = ['y','m','w','d']

	def initialize(age)
	  @age = age
	end

	def cleanse_age_unit
	  YEAR_AGE_UNIT.each{|year|
		@age = @age.gsub(year, 'y')
	  }
	  MONTH_AGE_UNIT.each{|month|
		@age = @age.gsub(month, 'm')
	  }
	  WEEK_UNIT.each{|week|
		@age = @age.gsub(week, 'w')
	  }
	  DAY_UNIT.each{|day|
		@age = @age.gsub(day, 'd')
	  }
	  @age = @age.strip
	end

	def process_age
	  cleanse_age_unit
	  if compound_age?
			case
			when @age.match?('y')
			  @age = @age.slice(0..(str.index('y')))
			  @age = @age.to_i + 1
			  @age = "#{@age}y"
			when @age.match?('m')
			  @age = @age.slice(0..(str.index('m')))
			  @age = @age.to_i + 1
			  @age = "#{@age}m"
			when @age.match?('w')
			  @age = @age.slice(0..(str.index('w')))
			  @age = @age.to_i + 1
			  @age = "#{@age}w"
			end
	  end
	  @age
	end

	def compound_age?
		cleanse_age_unit
		@age = @age.gsub(/\s+/, "")
		unit_count = 0
		AGE_RANK.each{|u|
			unit_count = @age.count(u)
		}
		unit_count > 1 
	end
end