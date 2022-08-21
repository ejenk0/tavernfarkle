extends RigidBody


var rng = RandomNumberGenerator.new()
var init_pos: Vector3

var hovered: bool = false
var selected: bool = false

var saved: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
#	rng.seed = 1
	self.init_pos = self.translation
	
func random_vector3(range_min: float, range_max: float):
	return Vector3(rng.randf_range(range_min, range_max), rng.randf_range(range_min, range_max), rng.randf_range(range_min, range_max))

func reset_and_throw(positive_z: bool):
	self.selected = false
	var z_throw: float
	if positive_z:
		z_throw = 40
	else:
		z_throw = -40
	self.translation = self.init_pos
	self.rotation_degrees = random_vector3(-180, 180)
	self.linear_velocity = Vector3.ZERO
	self.angular_velocity = Vector3.ZERO
	self.apply_impulse(Vector3.ZERO, Vector3(rng.randf_range(-10, -10), rng.randf_range(-35, -25), z_throw))
	self.apply_torque_impulse(self.random_vector3(-2, 2))

func bump(intensity: float = 1):
	self.apply_impulse(Vector3.ZERO, Vector3(4, 7, 4) * intensity)
	self.apply_torque_impulse(self.random_vector3(-5, 5) * intensity)

func still():
	return self.angular_velocity.length_squared() < 0.02 and self.linear_velocity.length_squared() < 0.01

func grounded():
	# Determine if die is still and on the ground
	return still() and self.global_translation.y < 1.3

func face_value():
	var x = round(self.rotation_degrees.x)
	var z = round(self.rotation_degrees.z)
	if x == 0:
		if z == 0:
			return 6
		if z == 180 or z == -180:
			return 1
		if z == -90:
			return 3
		if z == 90:
			return 4
	if x == 90:
		return 5
	elif x == -90:
		return 2


func _physics_process(_delta):
	if self.saved:
		self.collision_mask = 0b011
		self.sleeping = true
	else:
		self.collision_mask = 0b111
		self.sleeping = false
#	If the die isn't turning much and it is not on the ground and 
#	not high near where it was thrown, bump it.
	if (
		still() and
		self.global_translation.y > 1.2 and
		self.global_translation.y < 5 and
		not self.saved
		):
		self.bump()
	

	$DieHoverOutline.visible = self.hovered and !self.selected and $"..".dice_selectable() and not self.saved
	self.hovered = false
	$DieSelectedOutline.visible = self.selected and $"..".dice_selectable() and not self.saved

	


func _on_body_entered(_body):
	if self.linear_velocity.length_squared() + self.angular_velocity.length_squared() > 3:
#		$RandomSFX.unit_db = 1 * max(5, min(50, (self.linear_velocity.length_squared() + self.angular_velocity.length_squared()) / 30))
		$RandomSFX.play()
