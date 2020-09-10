extends TabContainer

var upgrades : Array = [
	{
		"name":"tmp",
		"cost":1,
		"param":"reproduce_chance",
		"bonus":0,
		"status":"to_buy"
	},
	{
		"name":"test",
		"cost":2,
		"param":"",
		"action": funcref(self, "action"),
		"status":"to_buy"
	}
]

func _ready():
	for upgrade in upgrades :
		pass
	print('ok')

		

