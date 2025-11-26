extends Node2D

const MAP_SCALE: int = 4 # that many pixel make one tile (4x4 tiles)
var map_width: int
var map_height: int
var trail_map: Array # A 2d map array to hold pheremone values, recieves the same resolution as the map

const DECAY_RATE: float = 0.05   # How fast the pheromone disappears
const DIFFUSION_RATE: float = 0.1 # How much the pheromone spreads

@export var number_of_agents: int = 1000 # Variable for the number of agents
@export_range(10.0, 500.0) var AGENT_SPEED: float = 250.0 # speed of the moving agents
@export var var_agent_size: float = 2.0 #changable agent size (appended to a absolute sine wave

@export_range(0.1, 10.0) var TURN_STRENGTH: float = 4.0
@export_range(0.1, 10.0) var RANDOM_TURN_AMOUNT: float = 0.01 # Small random perturbation in radians
@export_range(1, 10) var SIMULATION_STEPS_PER_FRAME: int = 1
const DEPOSIT_AMOUNT: float = 2.0 # The amount of pheromone an agent deposits	

var agent_color = Color("#FFD700")  #agent color
var time : float = 0 # input for sine wave
var agent_size: float # original variable, obsolete after change. Maybe adjust (?)

var agents: Array[Agent] = [] #array to hold all agents

func _ready():
	# Initialize the trail map size based on the viewport and scale
	var screen_size = get_viewport_rect().size
	map_width = int(screen_size.x / MAP_SCALE)
	map_height = int(screen_size.y / MAP_SCALE)
	# Initialize the 2D array (every coordinate filled with 0.0, same size as normal map)
	trail_map.resize(map_width)
	for i in map_width:
		trail_map[i] = Array()
		trail_map[i].resize(map_height)
		trail_map[i].fill(0.0)
	
	_initialize_agents()
	randomize()

func _initialize_agents():
	

	# Get the area where agents can start (e.g., the screen size)(has a .x and .y exstension)
	var screen_size = get_viewport_rect().size

	# Loop to create and add the agents
	for i in number_of_agents:

		var middle_x = screen_size.x / 2 #middle point of the screen
		var middle_y = screen_size.y / 2 #middle part of the screen
		var fixed_direction = i * 360.0 / number_of_agents  # angle in degrees, loops through 360 degrees the the amount of agents you have
		var radius = 200 #how far from the middle point the agents spawn
		var angle = deg_to_rad(fixed_direction)  # convert degrees to radians
		var start_x = middle_x + cos(angle) * radius #don't know how this works
		var start_y = middle_y + sin(angle) * radius #don't know how this works
		
		var start_position = Vector2(start_x, start_y)
		
		# 2. Spawn the agents in random directions (from 0 to 2*PI, aka TAU)
		var random_direction = randf_range(0.0, TAU)

		# 3. spawn a new agent
		var agent = Agent.new(start_position, random_direction, AGENT_SPEED)

		# 4. Add the agent to the array
		agents.append(agent)

	print("Initialized %s agents." % agents.size())

# Converts a screen position (Vector2) to a map cell coordinate (Vector2)
func _world_to_map(world_pos: Vector2) -> Vector2:
	var map_x = int(world_pos.x / MAP_SCALE)
	var map_y = int(world_pos.y / MAP_SCALE)
	# Clamp to ensure it's within the map bounds
	map_x = clamp(map_x, 0, map_width - 1)
	map_y = clamp(map_y, 0, map_height - 1)
	return Vector2(map_x, map_y)

# Reads the pheromone value at a map cell
func _get_pheromone_value(map_coords: Vector2) -> float:
	return trail_map[int(map_coords.x)][int(map_coords.y)]

# Deposits pheromone at an agent's location
func _deposit_pheromone(agent: Agent):
	var map_coords = _world_to_map(agent.position)
	var pheremone_x = int(map_coords.x)
	var pheremone_y = int(map_coords.y)
	
	# Deposit the pheromone (clamping it to a max value to prevent overflow (in this case 10.0))
	trail_map[pheremone_x][pheremone_y] = min(trail_map[pheremone_x][pheremone_y] + DEPOSIT_AMOUNT, 10.0)


# _process wordt elke frame gecalled, delta is tijd sinds laatste call
func _process(delta):
	time += delta
	agent_size = (abs(sin(time) * var_agent_size)+3) #pulsing of agents to replicate the real slime mold
	queue_redraw()
	var sub_delta = delta / SIMULATION_STEPS_PER_FRAME #control of time by changing delta

	for i in SIMULATION_STEPS_PER_FRAME:
		_move_agents(sub_delta) #move agents basesd on the assigned timestep

# The core logic for agent movement and steering
func _move_agents(delta: float):
	var screen_size = get_viewport_rect().size
	var turn_speed = TURN_STRENGTH * delta
	
	for agent in agents:
		# 1: Pheromone Deposit
		_deposit_pheromone(agent)
		
		# 2: Steering Logic (Sensor Reading)
		var dir_L = agent.direction - Agent.SENSOR_ANGLE_OFFSET
		var dir_F = agent.direction
		var dir_R = agent.direction + Agent.SENSOR_ANGLE_OFFSET
		
		# Calculate sensor positions (world coordinates)
		var pos_L = agent.position + Vector2.from_angle(dir_L) * Agent.SENSOR_OFFSET
		var pos_F = agent.position + Vector2.from_angle(dir_F) * Agent.SENSOR_OFFSET
		var pos_R = agent.position + Vector2.from_angle(dir_R) * Agent.SENSOR_OFFSET
		
		# Read pheromone values at sensor positions
		var val_L = _get_pheromone_value(_world_to_map(pos_L))
		var val_F = _get_pheromone_value(_world_to_map(pos_F))
		var val_R = _get_pheromone_value(_world_to_map(pos_R))
		
		# Slime Mold Steering Rule:
		if val_F > val_L and val_F > val_R:
			# If front sensor is highest, no turn (or slight random turn)
			agent.direction += randf_range(-RANDOM_TURN_AMOUNT, RANDOM_TURN_AMOUNT)
		elif val_L > val_R:
			# If left is highest, turn left
			agent.direction -= turn_speed
		elif val_R > val_L:
			# If right is highest, turn right
			agent.direction += turn_speed
		elif val_L == val_R:
			# If left and right are equal (and greater than front), pick a random direction
			if randf() < 0.5:
				agent.direction -= turn_speed
			else:
				agent.direction += turn_speed
		# The agent will always have a slight random turn to avoid getting stuck
		else:
			agent.direction += randf_range(-RANDOM_TURN_AMOUNT, RANDOM_TURN_AMOUNT)

		# Normalize the direction to stay within [0, 2*PI]
		agent.direction = wrapf(agent.direction, 0.0, TAU)
		
		# 3: Movement
		var velocity = Vector2.from_angle(agent.direction) * agent.speed

		# positie updated
		agent.position += velocity * delta

		# teleporteer naar de andere edge (Wrap-around boundary)
		agent.position.x = wrapf(agent.position.x, 0.0, screen_size.x)
		agent.position.y = wrapf(agent.position.y, 0.0, screen_size.y)

# agents tekenen
func _draw():
	
# 1. Loop through every cell in the trail_map
	for x in map_width:
		for y in map_height:
			var pheromone_value = trail_map[x][y]
			
			# Skip drawing if the pheromone is 0
			if pheromone_value <= 0.0:
				continue

			# Higher value = more opaque/lighter color
			var normalized_value = pheromone_value / 20.0

			# Create a faint color based on the value
			# Example: A blue color that gets more opaque as value increases
			var trail_color = Color(1.0, 1.0, 0.6, normalized_value) 

			# 3. Calculate screen position and size
			var rect_pos = Vector2(x * MAP_SCALE, y * MAP_SCALE)
			var rect_size = Vector2(MAP_SCALE, MAP_SCALE)
			var under_rect_size = Vector2(MAP_SCALE + 2, MAP_SCALE + 2)
			# 4. Draw the cell
			draw_rect(Rect2(rect_pos, under_rect_size), trail_color)
			draw_rect(Rect2(rect_pos, rect_size), trail_color)

	for agent in agents:
		draw_circle(agent.position, agent_size, agent_color)
