## Location.rb ##
require 'logger'

class Location
	attr_accessor :gameTimer, :name

	def initialize(params = {})
		@gameTimer = params.fetch(:gameTimer)
		@@currentTime = @gameTimer.currentTime
		@name = params.fetch(:name)

		# system #
		@config = YAML.load_file("./lib/location/location_config.yaml")
		@is_running = false
		@status = true
		
		# regens #
		@regens = @config["location"]["regens"]
		# @@regen_status = false
		@@regen_status = {} # {"food"=>{"meat"=>false, "fruit"=>false}}
		@@regenTimer = {} # {"food"=>{"meat"=>1479075122, "fruit"=>1479075122}}
		@regens.each do |genre,items|
			items.keys.each do |item|
				@@regen_status[genre] = {} if @@regen_status[genre].nil?
				@@regen_status[genre][item] = false
				@@regenTimer[genre] = {} if @@regenTimer[genre].nil?
				@@regenTimer[genre][item] = @@currentTime
			end
		end
		# p @regens.keys
		 # p @@regen_status.values.reduce(Hash.new, :merge)

		@logger = Logger.new(STDERR)
		@logger.level = Logger::DEBUG
		@logger.progname = "Location[#{@name}]"

		# resources #
		@inventory = Inventory.new(:owner => self, :genre => "location")
		@inventory.add_item_to_inventory("food", Item.new(:gameTimer => $gameTimer, :owner => self, :name => "meat", :amount => 0), 0)
		@inventory.add_item_to_inventory("food", Item.new(:gameTimer => $gameTimer, :owner => self, :name => "fruit", :amount => 0), 10)
		# @inventory.add_item_to_inventory("food", Food.new(:gameTimer => $gameTimer, :owner => self, :name => "wood", :amount => 0), 10)
	end

	def run
		if !@is_running
			@is_running = true
			thr = Thread.new do
				while true
					break if !@status
					@regens.each do |genre, items|
						items.each do  |item, regenStats|
							@@regen_status[genre][item] = regenLocationItem(genre, item, regenStats["regenRate"], regenStats["regenAmount"])
							@@regenTimer[genre][item] = @gameTimer.currentTime if @@regen_status[genre][item]
						end
					end
				end
			end
		end
	end

	def name
		return @name
	end

	def food
		return @food
	end

	def isInventoryItemZero(genre, item)
		#p @inventory.inventory[genre][item].amount
		amount = @inventory.inventory[genre][item].amount
		return true if amount.zero?
		return false
	end

	## location settings ##
	def regenLocationItem(genre, item, regenRate, regenAmount) ## __BUG__ currentTime applies only to one of the items and skips the other
		if @@regenTimer[genre][item] + regenRate <= @gameTimer.currentTime 
			statChange(self, "increase", genre, item, regenAmount, "regen") if !regenAmount.zero?
			#p item , @@currentTime , regenRate, @gameTimer.currentTime 
			return true
		else
			return false
		end
	end

	def statChange(owner, type, genre, item, requestedAmount, reason)
		receivedAmount = @inventory.statChange(owner, type, genre, item, requestedAmount, reason)
		return receivedAmount if receivedAmount.zero?
		#@logger.debug "#{genre} #{owner.name} #{type} by #{receivedAmount} - Amount = #{@inventory.inventory[genre][item].amount} due to #{reason}" 
		return receivedAmount
	end

end