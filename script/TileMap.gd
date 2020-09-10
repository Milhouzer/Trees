extends TileMap

var interface

const UNITARY_TILE : Array = [[0,0],[1,0.5],[0,1],[-1,0.5]]

const BASE_X : Vector2 = Vector2(16, 8)
const BASE_Y : Vector2 = Vector2(-16, 8)
## TO DO -> Merge trees_doc and AREAS
#var AREAS : Dictionary = {
#	"Apple" : appleArea
#}                    2    3    4    5
const PROB : Array = [ 0.1, 0.5, 0.9, 1]

# To do :
# With flower season : load flowers on trees, if no flowers, no reproduction for the season.
const trees_doc : Dictionary = {
	"types":["Apple","Peach","Pear"],
	"Apple":
		{
			"id":0,
			"reproduction_chance":0.001,
			"reproduce_season":[2,3],
			"flowers_season":[0,1,2],
			"flowers_max":120
		},
	"Peach":
		{
			"id":1,
			"reproduction_chance":0.001,
			"reproduce_season":[5,6,7,8,9],
			"flowers_season":[1,2],
			"flowers_max":120

		},
	"Pear":
		{
			"id":2,
			"reproduction_chance":0.001,
			"reproduce_season":[5,6,7,8,9],
			"flowers_season":[0,1,2],
			"flowers_max":120

		},
	"Apricot":
		{
			"id":0,
			"reproduction_chance":0.001,
			"fruit_season":[5,6,7],
			"flowers_season":[2,3],
			"flowers_max":120
		}
}

# Default configuration
var config  : Dictionary = {
	"Player":
	{
		"tree":"Apple",
		"count":1,
		"pos":{"x":15,"y":15},
	},
	"CPU":
		[
			{
				"tree":"Pear",
				"count":1,
				"pos":{"x":30,"y":20},
			},
			{
				"tree":"Peach",
				"count":1,
				"pos":{"x":40,"y":10},
			}
		]
}

export var ingame : Dictionary = {}

func flowers(x : float, r : float) -> float:
	return ceil(120*(1 - exp(-(x/r))))

# Return tile id of a tree | string if error
func findIdByType(type : String):
	var id = trees_doc.types.find(type)
	if id == -1:
		return "Invalid tree name"
	else :
		return id

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

# getNeighbours method
# array pos, int r
# return array containing all tiles in a square of r tiles from position pos
func getNeighboursByRadius(pos : Dictionary, r : int) -> Array:
	var tiles : Array = []
	for i in range(-r,r + 1):
		for j in range(-r,r + 1):
			tiles.append([pos.x + i, pos.y + j])
	return tiles

func set_active_upgrade(upgrade : Dictionary):
	print('set active upgrade on tilemap')
	var tree : String = config.Player.tree
	
	ingame[tree].flowers -= upgrade.cost
	var tmp = interface.get_node("Fertile")
	print(tmp)
	for param in upgrade.params:
		trees_doc[tree][param] = trees_doc[tree][param] * (1 + upgrade.params[param])
	
func checkForCollisionBeforePlantingTree(pos : Dictionary) -> Dictionary:
	var area : Dictionary = {"filled":[],"empty":[]}
	var tiles = getNeighboursByRadius(pos, 1)

	for tile in tiles:
		var filled : bool = false
		var tile_params = {"x":tile[0],"y":tile[1]}

		for tree_type in trees_doc.types:
			var tree_area = get_node_or_null(tree_type + "Area")
			if tree_area:
				if tree_area.get_cell(tile[0], tile[1]) != -1:
					tile_params.type = tree_type
					filled = true

		if (filled): area.filled.append(tile_params)
		else: area.empty.append(tile_params)
	return area

# Create new tree (type) on tile (pos {x,y})
func plantTree(type : String, pos : Dictionary) -> void:
	var id : int = findIdByType(type)
	if get_cell(pos.x, pos.y) != -1:
		pass
	var areas : Dictionary = checkForCollisionBeforePlantingTree(pos)
	var area : Dictionary = countAreaBeforePlanting(type, areas)
	if area.status == "plant":
		var tiles : Array = getNeighboursByRadius(pos, 1)
		if(setArea(type + "Area", tiles)):
			self.set_cell(pos.x, pos.y, id)
			var new_cells : Array = get_used_cells_by_id(id)
			ingame[type].tiles = new_cells
			ingame[type].flowers = 0.1
			setTotalTreeArea(type, get_node_or_null(type + "Area").get_used_cells_by_id(0).size())

	elif area.status == "randomize":
		if randf() < area.probability:
			var tiles : Array = getNeighboursByRadius(pos, 1)
			if(setArea(type + "Area", tiles)):
				self.set_cell(pos.x, pos.y, id)
				var new_cells : Array = get_used_cells_by_id(id)
				ingame[type].tiles = new_cells
				ingame[type].flowers = 0.1
				get_tree().get_root().get_node("Node2D/Camera2D/CanvasLayer/Interface").flowers_label.set_text(String(floor(ingame[type].flowers * 0.01)))
				setTotalTreeArea(type, get_node_or_null(type + "Area").get_used_cells_by_id(0).size())
	elif area.status == "pass":
		pass

func countAreaBeforePlanting(type : String, areas : Dictionary) -> Dictionary:
	if(areas.filled.size()):
		var ally_area : int = 1
#		var ennemy_area : int = 0
		for area in areas.filled:
			if area.type == type:
				ally_area += 1
		if ally_area <= 6:
			print(1/float(ally_area))
			return {"status":"randomize","probability":1/float(ally_area)}
		else :
			return {"status":"pass"}
	else:
		return {"status":"plant"}

func setTotalTreeArea(type : String, area : int):
	if(area):
		ingame[type].area = area
	return true

func setArea(nodeName : String, tiles : Array) -> bool:
	var TreeTile = get_node_or_null(nodeName)
	if TreeTile:
		for tile in tiles:
			TreeTile.set_cell(tile[0],tile[1], 0)
		return true
	else: return false

# Checks if config is valid i.e if trees exists
func isValidConfig(config : Dictionary) -> Dictionary:
	var isValid = {}
	for key in config.CPU:
		if trees_doc.types.find(key.tree, 0) == -1 :
			isValid = {"error":"CPU " + key.tree + " incorrect tree"}
		else:
			ingame[key.tree] = {}
	if trees_doc.types.find(config.Player.tree,0) == -1:
		isValid = {"error":"Player incorrect tree"}
	else:
		ingame[config.Player.tree] = {}
	return isValid

func startWithConfig() -> void:
	createIsometricTilemap(config.Player.tree, "isometric", Vector2(32, 16), "res://Ressources/area.tres", [Vector2(64,0), Vector2(0, 64), Vector2(0, 0)], 16)
	for _x in range(config.Player.count):
		plantTree(config.Player.tree, config.Player.pos)
	for cpu in config.CPU:
		createIsometricTilemap(cpu.tree, "isometric", Vector2(32, 16), "res://Ressources/area.tres", [Vector2(64,0), Vector2(0, 64), Vector2(0, 0)], 16)
		for _x in range(cpu.count):
			plantTree(cpu.tree, cpu.pos)

	print("Game started")
	print("var ingame : ", ingame)

func createIsometricTilemap(name : String, mode : String, cell_size : Vector2, tile_set : String, transformation : Array, cell_quadrant_size : int) -> void:
	var new_area = TileMap.new()
	new_area.name = name + "Area"
	if(mode == "isometric"):
		new_area.mode = TileMap.MODE_ISOMETRIC
	new_area.cell_size = cell_size
	new_area.tile_set = load(tile_set)
	var trans = Transform2D(transformation[0], transformation[1], transformation[2])
	new_area.cell_custom_transform = trans
	new_area.cell_quadrant_size = cell_quadrant_size
	add_child(new_area, true)
	new_area.hide()

# random process to reproduce a tree
# To do : check if the chosen area is available
func randomizeForReproduction(type : String, pos : Dictionary) -> void:
	var index : int = 0
	var rd : float = randf()

	if rd < trees_doc[type].reproduction_chance:
		rd = randf()
		while rd >= PROB[index] and index != len(PROB):
			index += 1
		var neighbours : Array = getNeighboursByRadius(pos, index + 2)
		var chosen : Array = neighbours[randi()%len(neighbours)]
		plantTree(type, {"x":chosen[0], "y":chosen[1]})
		
func _ready():
	randomize()

	var isValid : Dictionary = isValidConfig(config)
	interface = get_tree().get_root().get_node("Node2D/Camera2D/CanvasLayer/Interface")

	if(isValid):
		ingame = {}
		print(isValid.error)
	else :
		startWithConfig();

func _process(delta):
	for type in ingame:
		if(interface.current_month in trees_doc[type].reproduce_season):
#			print('ok')
			if(ingame[type].flowers >= 1):
				for location in ingame[type].tiles:
					randomizeForReproduction(type, {"x":location[0], "y":location[1]})
					if type == config.Player.tree:
						set_flowers_amout_and_set_text(-0.01, type)
		if(interface.season_status == "HIVERNAL_REST"):
			"ok"
			#develop roots

func set_flowers_amout_and_set_text(amount : float, type : String):
	ingame[type].flowers += amount
	interface.flowers_label.set_text(String(floor(ingame[type].flowers)))
	return true
	
# Update flowers on trees every second
func _on_Flowers_timeout() -> void:
	for type in ingame:
		if type == config.Player.tree:
			if(ingame[type].flowers != 0 && interface.temperature < 0):
				ingame[type].flowers = 0
				set_flowers_amout_and_set_text(-ingame[type].flowers, type)
			if(interface.current_month in trees_doc[type].flowers_season):
				var days : int = 0
				for i in range(interface.current_month - trees_doc[type].flowers_season[0]):
					days += interface.months[String(interface.current_month - i)].days_number
				days += interface.current_day
				set_flowers_amout_and_set_text(abs(ingame[type].flowers - floor(flowers(days, 2400))), type)

