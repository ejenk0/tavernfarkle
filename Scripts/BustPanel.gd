extends RigidBody


var rng = RandomNumberGenerator.new()
var init_pos: Vector3

# Which direction should the panel enter from?
export var positive_z: bool

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	self.init_pos = self.translation
	self.exit()

func home():
	self.angular_velocity = Vector3.ZERO
	self.linear_velocity = Vector3.ZERO
	self.translation = self.init_pos

func launch():
	var z
	var speed = 23
	if positive_z:
		z = speed
	else:
		z = -speed
	
	self.apply_central_impulse(Vector3(rng.randf_range(-3, 3), -3, z))
	self.apply_torque_impulse(Vector3(rng.randf_range(10, 25), rng.randf_range(60, 120), 0))

func enter():
	self.sleeping = false
	self.home()
	self.show()
	self.launch()

func exit():
	self.sleeping = true
	self.hide()
	self.home()
