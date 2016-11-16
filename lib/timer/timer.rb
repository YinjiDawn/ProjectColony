## timer.rb ##

require 'logger'

class Timer
	attr_accessor :gamspeed

	def initialize(params = {})
		@gamespeed = params.fetch(:gamespeed)
		@logger = Logger.new(STDERR)
		@logger.level = Logger::INFO
		@logger.progname = "Timer"
		@currentTime = 1479075122
	end

	def gamespeed
		@logger.debug "Gamespeed = #{@gamespeed}"
		return @gamespeed
	end

	def setGamespeed(gamespeed)
		@gamespeed = gamespeed
	end

	def currentTime
		@logger.debug "currentTime = #{@currentTime}"
		return @currentTime
	end

	def run
		Thread.new do
			now = Time.now.to_i
			counter = 1
			while true
			  if Time.now.to_i < now + counter
			    next
			  else
			    @currentTime += @gamespeed
			  end
			  counter += @gamespeed
			end
		end
	end

end