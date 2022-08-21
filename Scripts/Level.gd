extends Spatial

var ray_origin = Vector3()
var ray_target = Vector3()

var last_intersection

var p1_score: int
var p2_score: int

var p1_round_score: int
var p2_round_score: int

var players_data
var active_player_index: int

var settled: bool = false

export var single_player: bool
var bot_move = []
var bot_pass: bool = false

func reset_game():
	self.p1_score = 0
	self.p2_score = 0
	self.p1_round_score = 0
	self.p2_round_score = 0

func array_in_array(find: Array, in_array: Array) -> bool:
	for value in find:
		if not value in in_array:
			return false
	return true

func score_dice(dice_values: Array):
	var score: int = 0
	var spares: int = 0
	
#	Full straight
	if array_in_array([1, 2, 3, 4, 5, 6], dice_values):
		score += 1500
		return [score, 0]
	
#	High straight
	if array_in_array([2, 3, 4, 5, 6], dice_values):
		score += 750
		for i in [2, 3, 4, 5, 6]:
			dice_values.erase(i)
	
#	Low straight
	if array_in_array([1, 2, 3, 4, 5], dice_values):
		score += 500
		for i in [1, 2, 3, 4, 5]:
			dice_values.erase(i)
	
	for i in range(1, 7):
#		3 or more of a kind
		if dice_values.count(i) >= 3:
			var v
			if i == 1:
				v = 10
			else:
				v = i
			score += pow(2, dice_values.count(i) - 3) * 100 * v
		
#		Individual 1s
		elif i == 1:
			score += 100 * dice_values.count(i)
		
#		Individual 5s
		elif i == 5:
			score += 50 * dice_values.count(i)
		
		else:
			spares += dice_values.count(i)
		
	return [score, spares]

func update_labels():
	var index = 0
	for i in self.players_data:
		index += 1
		i.label.text = """Player %s
	Score: %s
	Round Score: %s
	""" % [
		index,
		i.score,
		i.round_score
		]
	
	$SelectedValueLabel.text = str(score_dice(current_dm().get_selected_values())[0])

func _ready():
	reset_game()
	self.players_data = [
		{
			"dicemanager": $DiceManager1,
			"score": 0,
			"round_score": 0,
			"label": $Player1Info,
			"bustpanel": $BustPanel1
		},
		{
			"dicemanager": $DiceManager2,
			"score": 0,
			"round_score": 0,
			"label": $Player2Info,
			"bustpanel": $BustPanel2
		}
	]
	var global = get_node("/root/Global")
	single_player = global.single_player
	risk_tolerance = global.bot_risk_tolerance
	self.active_player_index = 0
	self.players_data[1].dicemanager.set_visibility(false)
	self.throw_current()

func current_dm():
	return self.players_data[self.active_player_index].dicemanager

func throw_current():
	current_dm().reset_and_throw_all()
	self.settled = false

func current_bust():
	if current_dm().get_face_values() and score_dice(current_dm().get_face_values())[0] == 0:
		return true
	return false

func next_player():
	self.active_player_index = (self.active_player_index + 1) % 2
	current_dm().unsave_all()
	current_dm().set_visibility(true)
	self.players_data[self.active_player_index].bustpanel.exit()
	self.bot_move = []
	self.bot_pass = false

func _physics_process(_delta):
	if not OS.has_touchscreen_ui_hint():
	#	Raycast mouse to get hovered die
		var mouse_position = get_viewport().get_mouse_position()

		ray_origin = $Camera.project_ray_origin(mouse_position)

		ray_target = ray_origin + $Camera.project_ray_normal(mouse_position) * 1000

		var space_state = get_world().direct_space_state
	#	Intersect with layer 2 only (dice)
		last_intersection = space_state.intersect_ray(
			ray_origin,
			ray_target,
			[self],
			0b10
			)

		if not last_intersection.empty():
			last_intersection.collider.hovered = true

func _unhandled_input(event):
	if event is InputEventMouseButton and not OS.has_touchscreen_ui_hint():
		if event.button_index == 1 and event.pressed:
			if not last_intersection.empty() and last_intersection.collider.get_parent().dice_selectable() and not (active_player_index == 1 and single_player):
#				Toggle selection
				last_intersection.collider.selected = !last_intersection.collider.selected
		elif event.button_index == 2:
			select_move()
#	Mobile Controls
	if event is InputEventScreenTouch:
		if event.pressed:
			ray_origin = $Camera.project_ray_origin(event.position)
	
			ray_target = ray_origin + $Camera.project_ray_normal(event.position) * 1000

			var space_state = get_world().direct_space_state
		#	Intersect with layer 2 only (dice)
			last_intersection = space_state.intersect_ray(
				ray_origin,
				ray_target,
				[self],
				0b10
				)
			
			if not last_intersection.empty() and last_intersection.collider.get_parent().dice_selectable() and not (active_player_index == 1 and single_player):
				last_intersection.collider.selected = !last_intersection.collider.selected

func select_dice(dice_values: Array, deselect_others: bool = true):
#	copy array
	var values = [] + dice_values
	if deselect_others:
		current_dm().deselect_all()
	for i in dice_values:
		current_dm().select_value(i)

var bot_play_delay = 0
var bot_play_time = 2

var failsafe_timer = 0
var failsafe_cap = 6
var bump_attempts = 0

func _process(delta):
	if self.current_bust():
		self.players_data[self.active_player_index].bustpanel.enter()
		self.players_data[self.active_player_index].round_score = 0
		self.next_player()
		self.throw_current()
	
	if current_dm().all_grounded() and current_dm().get_face_values() and not settled:
		self.settled = true
	
	if settled:
		failsafe_timer = 0
		bump_attempts = 0
	else:
		failsafe_timer += delta
	
	if failsafe_timer >= failsafe_cap:
		failsafe_timer = 0
		if bump_attempts < 3:
			current_dm().unstick()
			bump_attempts += 1
		else:
			throw_current()
			bump_attempts = 0
			
	
	if (
		self.settled and
		self.single_player and 
		self.active_player_index == 1 and
		not current_bust()
		):
		if len(self.bot_move) == 0:
			var move = select_move()
			self.bot_move = move[0]
			self.bot_pass = move[1]
			select_dice(self.bot_move)
		elif bot_play_delay > bot_play_time:
			if self.bot_pass:
				_on_PassButton_pressed()
			else:
				_on_RollButton_pressed()
			self.bot_move = []
			bot_play_delay = 0
		else:
			bot_play_delay += delta
		
	var selected_score_spares = score_dice(current_dm().get_selected_values())
	
	$RollButton.disabled = (!self.settled) or selected_score_spares[0] == 0 or selected_score_spares[1] > 0 or (active_player_index == 1 and single_player)
	$PassButton.disabled = (!self.settled) or selected_score_spares[0] == 0 or selected_score_spares[1] > 0 or (active_player_index == 1 and single_player)
	
	self.update_labels()


func _on_RollButton_pressed():
	self.players_data[self.active_player_index].round_score += score_dice(current_dm().get_selected_values())[0]
	self.current_dm().save_selected()
	if len(self.current_dm().get_not_saved_children()) == 0:
		self.current_dm().unsave_all()
	self.throw_current()


func _on_PassButton_pressed():
	self.players_data[self.active_player_index].round_score += score_dice(current_dm().get_selected_values())[0]
	self.players_data[self.active_player_index].score += self.players_data[self.active_player_index].round_score
#	print("Round score: " + str(self.players_data[self.active_player_index].round_score) + " \nTotal score: " + str(self.players_data[self.active_player_index].score))	
	self.players_data[self.active_player_index].round_score = 0
	self.current_dm().save_selected()
	self.next_player()
	self.throw_current()


# BOT STUFF

var risk_tolerance: int = 0

# Expected scores PROVIDED not bust
const ex_scores = [
	75,
	90,
	119,
	169,
	262,
	410
]

const ex_bust = [
	0.66,
	0.44,
	0.28,
	0.16,
	0.08,
	0.03
]

func combs(a: Array):
	if len(a) == 0:
		return [[]]
	var cs = []
	for c in combs(a.slice(1, -1)):
		cs += [c, c + [a[0]]]
	return cs

func select_move():
	var dice_values = current_dm().get_face_values()
	var combinations = combs(dice_values)
	var diffs = []
	var scores = []
	var valid_combs = []
	for comb in combinations:
		var score_spare = score_dice(comb)
		if score_spare[0] and score_spare[1] == 0 and comb:
			var score = score_spare[0]
			var spare = len(dice_values) - len(comb)
			if spare <= 0:
				spare = 6
			var risk = (self.players_data[self.active_player_index].round_score + score) * ex_bust[spare - 1]
			var reward = score + ex_scores[spare - 1]
			var diff = reward - risk
			diffs.append(diff)
			scores.append(score)
			valid_combs.append(comb)
#			print(comb, " ", reward, " ", risk, " ", diff)
	
	var best_diff = diffs.max()
#	Take best diff and roll
	if best_diff >= risk_tolerance:
		var best_move = valid_combs[diffs.find(best_diff)]
		return [best_move, false]
#	Take highest score and pass
	var best_move = valid_combs[scores.find(scores.max())]
	return [best_move, true]
	
