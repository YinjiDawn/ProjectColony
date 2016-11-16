## Inventory.rb ##
require 'logger'
require 'yaml'

class Inventory
	attr_accessor :owner, :genre

	def initialize(params = {})
		@owner = params.fetch(:owner)
		@genre = params.fetch(:genre)

		# system #
		@config = YAML.load_file("./lib/inventory/inventory_config.yaml")
		@item_config = YAML.load_file("./lib/item/item_config.yaml")

		# stats #
		@inventory = @config["inventory"][@genre] # {"food"=>{}}
		# initialize inventory items ##
		@item_config["Item"].keys.each do |itemName|
			add_item_to_inventory("food", Item.new(:gameTimer => $gameTimer, :owner => @owner, :name => itemName, :amount => 0), 0)
		end

		@logger = Logger.new(STDERR)
		@logger.level = Logger::DEBUG
		@logger.progname = "Inventory[#{@owner.name}]"
	end

	def inventory
		return @inventory
	end

	def statChange(owner, type, genre, item, requestedAmount, reason)
		case type.downcase
		when "decrease"
			return 0 if @inventory[genre][item].amount <= 0
			requestedAmount = @inventory[genre][item].amount if @inventory[genre][item].amount < requestedAmount
			@inventory[genre][item].statChange(@owner, type, "amount", requestedAmount, reason)
			return requestedAmount
		when "increase"
			@inventory[genre][item].statChange(@owner, type, "amount", requestedAmount, reason)
			return requestedAmount
		when "set"
			@inventory[genre][item].statChange(@owner, type, "amount", requestedAmount, reason)
		end
	end

	# inventory actions #
	def add_item_to_inventory(genre, obj, amount)
		if @inventory[genre][obj.instance_variable_get(:@name)].nil?
			@inventory[genre][obj.instance_variable_get(:@name)] = obj 
		end
		@inventory[genre][obj.instance_variable_get(:@name)].statChange(@owner, "increase", "amount", amount, "add")
	end

end