extends Control

export var current_day : int = 01
export var global_day : int = 00
export var current_month : int = 0
export var current_year : int = 2020
export var temperature : float = getTemperature()
export var season_status : String = ""

export var months : Dictionary = getJSON("json/time.json")
var month_label
var day_label
var year_label
var temperature_label

var flowers_label

# Read content of JSON file
func getJSON(file : String):
	var data_file = File.new()
	if data_file.open("res://"+ file, File.READ) != OK:
		return "error opening json"
	var data_text = data_file.get_as_text()
	data_file.close()
	var data_parse = JSON.parse(data_text)
	if data_parse.error != OK:
		return
	else:
		return data_parse.result


func _ready():
	month_label = get_node("TimeContainer/NinePatchRect/MonthLabel")
	day_label = get_node("TimeContainer/NinePatchRect/DayLabel")
	year_label = get_node("TimeContainer/NinePatchRect/YearLabel")
	temperature_label = get_node("TimeContainer/NinePatchRect/TemperatureLabel")
	flowers_label = get_node("TimeContainer/NinePatchRect/FlowersLabel")
	
func updateTime() -> void:
	global_day +=1
	current_day += 1
	day_label.set_text("%02d" % current_day)
	if current_day > months[String(current_month)].days_number:
		current_day = 1
		day_label.set_text("%02d" % current_day)
		current_month += 1
		getSeasonStatus(current_month)
		if current_month > 11:
			global_day = 0
			current_month = 0
			getSeasonStatus(current_month)
			month_label.set_text(months[String(current_month)].name)
			current_year += 1
			year_label.set_text(String(current_year))
		else :
			month_label.set_text(months[String(current_month)].name)
	# if date = end_date: stop
	
func getSeasonStatus(month : int) -> void:
	if month == 10:
		season_status = "HIVERNAL_REST"
	if month == 9:
		season_status = "AUTONM"
	
func getTemperature() -> float:
	var x : float = (global_day - 180.0)/80
	temperature = stepify(28*exp(-(pow(x,2))) + 0.5*cos((360 - global_day)/(6 + sin(global_day/9))), 0.01)
	return temperature
		
func _on_Timer_timeout():
	updateTime();
#	day_label.set_text("%02d" % current_day)
	temperature_label.set_text(String(getTemperature()) + "°C")
