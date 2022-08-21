extends Node

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	for i in self.get_children():
		i.apply_impulse(Vector3.ZERO, Vector3(rng.randf_range(-20, -30), -5, rng.randf_range(-3, 3)))
		i.apply_torque_impulse(Vector3(rng.randf_range(-6, 6), rng.randf_range(-6, 6), rng.randf_range(-6, 6)))
