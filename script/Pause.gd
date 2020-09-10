extends Control

# status : "locked", "unlocked", "bought"
# "locked": player needs tobuy others to unlock it
# "inactive" : player can buy it
# "active" : player bought it
var tree_tile
var tilemap
var interface

var upgrades : Dictionary = {
	"Fertile" : {
		"cost":1,
		"params":{
			"reproduction_chance":0.02
		},
		"status":"inactive",
		"level":0
	},
	"Upgrade2":{
		"cost":2,
		"param":"",
		"action": funcref(self, "action"),
		"status":"locked"
	}
}
	
func action():
	return "working"
	
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
	interface = get_tree().get_root().get_node("Node2D/Camera2D/CanvasLayer/Interface")
	tilemap = get_tree().get_root().get_node("Node2D/TreesMap")
	print(tilemap)
	for button in get_tree().get_nodes_in_group("shop_buy_button"):
		button.connect("pressed", self, "_on_Button_pressed", [button])
	pass
	
	
func _input(event):
	if event.is_action_pressed("pause"):
		var new_pause_state = not get_tree().paused
		get_tree().paused = new_pause_state
		visible = new_pause_state

func setActiveUpgrade(node : String, upgrade : Dictionary, name : String) -> void:
	# set active upgrade on GUI
	var tree_tile = get_node(node)
	tree_tile.set_text(name)
	
	# set active upgrade on tilemap parameters
	tilemap.set_active_upgrade(upgrade)
	
	
func _on_Button_pressed(button) -> bool:
	var upgrade : Dictionary = upgrades[button.name]
	if upgrade:
		if upgrade.status == "locked":
			print("You need to unlock this upgrade first")
			return false
		elif upgrade.status == "inactive":
			var flowers : String = interface.flowers_label.get_text()
			if(int(flowers) >= upgrade.cost && int(flowers) > 0):
				setActiveUpgrade("ShopContainer/Tree/Tile/Stats" + "/" + button.name + "/Label", upgrade, button.name)
				upgrade.status = "active"
				if upgrade.level:
					upgrade.level += 1
				print("Upgrade bought")
				return true
			else:
				print("You don't have enought money to buy this upgrade")
		elif upgrade.status == "active":
			print("Upgrade already bought")
			return false
		else : 
			print("error, upgrade not available")
			return false
	return false
	pass # Replace with function body.
