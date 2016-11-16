## Food.rb ##
require 'logger'
require 'yaml'

class Food
	attr_accessor :gameTimer, :owner, :name, :amount

	def initialize(params = {})
		@gameTimer = params.fetch(:gameTimer)
		@owner = params.fetch(:owner)
		@name = params.fetch(:name)
		config = YAML.load_file('./lib/food/food_config.yaml')
		@recoveryAmount = config["Food"][@name]["recoveryAmount"]
		@genre = "food"



		@logger = Logger.new(STDERR)
		@logger.level = Logger::DEBUG
		@logger.progname = "Food[#{@owner.name}]"

		# stats #
		@amount = params.fetch(:amount)
		@recoveryType = config["Food"][@name]["recoveryType"]
	end

	def name
		return @name
	end

	def self.recoveryType
		@recoveryType
	end

	def self.recoveryAmount
		#@logger.debug "#{@name} healthRecovery = #{@healthRecovery}"
		@recoveryAmount
	end

	def self.amount
		@amount
	end

	def amount
		return @amount
	end

	def statChange(owner, type, stat, amount, reason)
		case type.downcase
		when "decrease"
			case stat.downcase
			when "amount"
				return false if @amount <= 0
				@amount -= amount
			end
		when "increase"
			case stat.downcase
			when "amount"
				@amount += amount
			end
		when "set"
			case stat.downcase
			when "amount"
				@amount = amount
			end
		end
		@logger.debug "#{owner.name} #{type} #{amount} food[#{@name}]. Amount = #{@amount} due to #{reason}"
	end

end