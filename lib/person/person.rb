## Person.rb ##
require 'logger'
require 'yaml'

class Person
	attr_accessor :gameTimer, :name, :location, :health, :energy

	def initialize(params = {})
		# system #
		@config = YAML.load_file("./lib/person/person_config.yaml")
		@gameTimer = params.fetch(:gameTimer)
		@@currentTime = @gameTimer.currentTime
		@is_running = false

		@@minRand = 60
		@@maxRand = 80
		@randDropFoodNumber = rand(@@minRand..@@maxRand)
		@@randDropEnergyNumber = rand(@@minRand..@@maxRand)

		# personal #
		@name = params.fetch(:name)
		@inventory = Inventory.new(:owner => self, :genre => "person")
		@@isDoingAction = false

		# @inventory.add_item_to_inventory("food", Item.new(:gameTimer => $gameTimer, :owner => self, :name => "meat", :amount => 0), 1) ##default
		# @inventory.add_item_to_inventory("food", Item.new(:gameTimer => $gameTimer, :owner => self, :name => "fruit", :amount => 0), 1) ##default
		
		# skills #
		@skills = @config["person"]["skills"] # {"collect"=>{"meat"=>{"min"=>1, "max"=>2}, "fruit"=>{"min"=>1, "max"=>4}}}

		@@currentActionTime = {}
		@@currentActionTimeStatus = {}
		@skills.each do |action, items|
			items.each do |item|
				@@currentActionTime[action] = {} if @@currentActionTime[action].nil?
				@@currentActionTime[action][item] = @gameTimer.currentTime
				@@currentActionTimeStatus[action] = {} if @@currentActionTimeStatus[action].nil?
				@@currentActionTimeStatus[action][item] = false
			end
		end

		# stats #
		@status = true
		@health = params.fetch(:health)
		@maxhealth = @config["person"]["stats"]["maxhealth"]
		@energy = params.fetch(:energy)
		@maxenergy = @config["person"]["stats"]["maxenergy"]

		# debuffs #
		@drops = @config["person"]["drops"] # {"health"=>{"rate"=>1, "amount"=>1}}
		@@drop_status = {}
		@@dropTimer = {}
		@drops.each do |stat,drop|
			@@drop_status[stat] = false
			@@dropTimer[stat] = @@currentTime
		end

		# needs #
		@need_food = false

		# location #
		@location = params.fetch(:location)

		# logs #
		@@statDropLog = false

		@logger = Logger.new(STDERR)
		@logger.level = Logger::DEBUG
		@logger.progname = "Person[#{@name}]"
	end

	def run
		if !@is_running
			@is_running = true
			thr = Thread.new do
				while true
					break if !@status
					@drops.each do |stat, drop|
						@@drop_status[stat] = statDrop(stat, drop)
						@@dropTimer[stat] = @gameTimer.currentTime if @@drop_status[stat]
					end
					checkNeeds
				end
			end
		end
	end

	## self ##

	def self.name
		@name
	end

	def name
		return @name
	end

	def self.health
		@health
	end

	def self.energy
		@energy
	end

	## logs ##
	def log(stat, type, amount, reason, printLog)
		if printLog
			case type
			when "health"
				@logger.info "#{stat} #{type} by #{amount} to #{@health} due to #{reason}"
			when "energy"
				@logger.info "#{stat} #{type} by #{amount} to #{@energy} due to #{reason}" 
			when "status"
				@logger.info "#{stat} #{type} to #{amount} due to #{reason} - DEAD" 
			end
		end
	end

	## Needs ##
	def checkNeeds
		checkFoodNeeds
		checkEnergyNeeds
	end

	def checkEnergyNeeds
		# energy check #
		if @energy < @@randDropEnergyNumber
			@@randDropEnergyNumber = rand(@@minRand..@@maxRand)
			actionOnSelf("rest", "sleep")
		end
	end

	def checkFoodNeeds
		# health check #
		if @health < @randDropFoodNumber
			@randDropFoodNumber = rand(@@minRand..@@maxRand)
			consumed = false
			@inventory.inventory["food"].keys.each do |foodName|
				next if @inventory.inventory["food"][foodName].amount <= 0
				break if consume("food", foodName, @inventory.inventory["food"][foodName], 1) 
			end
		end

		if @health <= 0 ## Dead 
			statChange(self, "set", "status", false, "no health", true)
		end

		## inventory food amount check #
		@inventory.inventory["food"].each do |foodName, item|
			if item.amount.zero?
				next if @location.isInventoryItemZero("food", foodName) ## Person has insight on the amount of resources in location // Won't waste time & energy on an empty resource
				collectMin = @skills["collect"][foodName]["min"]
				collectMax = @skills["collect"][foodName]["max"]
				actionOnLocation("collect", "food", foodName, "increase", rand(collectMin..collectMax))
				break if @@isDoingAction
			end
		end
	end

	## person settings ##

	def actionTime(action, item)
		@@isDoingAction = true
		if !@@currentActionTimeStatus[action][item]
			@@currentActionTimeStatus[action][item] = true
			@@currentActionTime[action][item] = @gameTimer.currentTime 
		end

		if @@currentActionTime[action][item] + @skills[action][item]["actionTime"] <= @gameTimer.currentTime 
			@@currentActionTimeStatus[action][item] = false
			@logger.info "#{action} #{item} took #{@skills[action][item]["actionTime"]} seconds."
			@@isDoingAction = false
			return true
		else
			return false
		end
	end

	def statDrop(stat, drop)
		dropRate = drop["rate"]
		dropAmount = drop["amount"]
		if @@dropTimer[stat] + dropRate <= @gameTimer.currentTime 
			statChange(self, "decrease", stat, dropAmount, "dropTick", @@statDropLog)
			return true
		else
			return false
		end
	end

	def statChange(owner, type, stat, amount, reason, printLog=true)
		case type.downcase
		when "decrease"
			case stat.downcase
			when "health"
				if @health > 0
					@health -= amount 
					log(type, stat, amount, reason, printLog)
					return true
				end
				return false
			when "energy"
				if @energy > 0
					@energy -= amount 
					log(type, stat, amount, reason, printLog)
					return true
				end
				return false
			end
		when "increase"
			case stat.downcase
			when "health"
				if @health + amount > @maxhealth
					@health = @maxhealth
				else
					@health += amount
				end
			when "energy"
				@energy += amount if @energy < 100
			end
		when "set"
			case stat.downcase
			when "health"
				@health = amount 
			when "energy"
				@energy = amount 
			when "status"
				@status = amount
			end
		end
		log(type, stat, amount, reason, printLog)
	end

	## person actions ##
	def consume(genre, item, item_obj, amount_consume)
		case genre
		when "food"
			inventoryChangeResult = item_obj.statChange(self, "decrease", "amount", amount_consume, "consume")
			statChange(self, "increase", item_obj.instance_variable_get(:@recoveryType), item_obj.instance_variable_get(:@recoveryAmount), "consume")
			return inventoryChangeResult
		end
		# @logger.debug "Inventory[#{@name}] consumed #{amount_consume} #{genre}[#{item}]. Amount left = #{food_obj.instance_variable_get(:@amount)}"
	end

	def actionOnSelf(action, item)
		if actionTime(action, item)
			actionCost = @skills[action][item]["actionCost"]
			if checkEnergyForAction(item, actionCost)
				minGain = @skills[action][item]["min"]
				maxGain = @skills[action][item]["max"]
				recoveryType = @skills[action][item]["recoveryType"]
				case item
				when "sleep"
					statChange(self, "increase", recoveryType, rand(minGain..maxGain), item)
				end
			end
		end
	end

	def actionOnLocation(action, genre, item, type, requestedAmount)
		if actionTime(action, item)
			actionCost = @skills[action][item]["actionCost"]
			if checkEnergyForAction(action, actionCost)
				case genre
				when "food"
					case type
					when "increase" ## increase inventory with genre[item] by requestedAmount
						receivedAmount = @location.statChange(self, "decrease", genre, item, requestedAmount, action)	
						if !receivedAmount.zero?
							@logger.debug "used #{actionCost} energy and has #{@energy} energy left due to #{action}" if statChange(self, "decrease", "energy", actionCost, action)
							@inventory.inventory[genre][item].statChange(self, type, "amount", receivedAmount, action) 
						else
							return 0
						end
					end
				end
				@logger.debug "#{type} #{genre}[#{item}] amount = #{receivedAmount}"
			else
				#@logger.debug "has #{@energy} energy left for #{action} - need #{actionCost} energy "
			end
		end
	end

	def checkEnergyForAction(action, actionCost)
		if @energy - actionCost >= 0
			return true
		else
			return false
		end
	end

end