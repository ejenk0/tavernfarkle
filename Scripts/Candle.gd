extends OmniLight

onready var noise = OpenSimplexNoise.new()
var value = 0.0
const MAX_VALUE = 100000000

export var brightness: float = 1
export var variance: float = 1

func _ready():
	randomize()
	value = randi() % MAX_VALUE
	noise.period = 16

func _physics_process(delta):
	value += 25 * delta
	if value > MAX_VALUE:
		value = 0.0
		
	var alpha = (noise.get_noise_1d(value) / (1/variance)) + brightness
#	print(delta, alpha)

	self.light_energy = alpha
