## main.rb ##
require './lib/person/person'
require './lib/food/food'
require './lib/item/item'
require './lib/timer/timer'
require './lib/location/location'
require './lib/inventory/inventory'
require 'logger'

def main
	$location.run
	$person.run
end

def init
	$logger = Logger.new(STDERR)
	$logger.level = Logger::INFO
	$logger.progname = "main"

	$gameTimer = Timer.new(:gamespeed => 1)
	$gameTimer.run

	
	$location = Location.new(:gameTimer => $gameTimer, :name => "Grassland")
	$person = Person.new(:gameTimer => $gameTimer, :name => "Henry", :location => $location, :health => 100, :energy => 100)
	#$person2 = Person.new(:gameTimer => $gameTimer, :name => "Bob", :location => $location, :health => 100, :energy => 100)
end

if _FILE_ = $PROGRAM_NAME
	init
	while true
		main
	end
end
