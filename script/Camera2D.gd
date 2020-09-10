extends Camera2D

func _ready():
	print(self.position)
	
func _process(_delta):
	if Input.is_action_pressed("ui_down") and self.position.y <= (self.limit_bottom - 240):
		self.position.y += 5
	if Input.is_action_pressed("ui_up") and self.position.y >= (self.limit_top + 240):
		self.position.y -= 5
	if Input.is_action_pressed("ui_left") and self.position.x >= (self.limit_left + 400):
		self.position.x -= 5
	if Input.is_action_pressed("ui_right") and self.position.x <= (self.limit_right - 400):
		self.position.x += 5
