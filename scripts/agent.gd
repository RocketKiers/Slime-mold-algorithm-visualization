class_name Agent

var position: Vector2 = Vector2.ZERO
var direction: float = 0.0  # turn graad in radians
var speed: float = 100.0   # pixels per seconde

# --- Sensor Constants (New) ---
# afstand van agent naar sensor
const SENSOR_OFFSET: float = 10.0
# hoek tussen sensoren in radians
const SENSOR_ANGLE_OFFSET: float = 0.5 # onvegeer 28.6 degrees



func _init(_position: Vector2, _direction: float, _speed: float):
	position = _position
	direction = _direction
	speed = _speed
