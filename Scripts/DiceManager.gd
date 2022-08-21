extends Node

export var player_index: int

# Which direction should thrown dice go?
export var positive_z: bool

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func get_not_saved_children():
	var kids = []
	for i in self.get_children():
		if !i.saved:
			kids.append(i)
	return kids

func set_visibility(visibility: bool):
	for i in self.get_children():
		i.visible = visibility

func unsave_all():
	for i in self.get_children():
		i.saved = false

func deselect_all():
	for i in self.get_children():
		i.selected = false

func select_value(value: int):
	for i in self.get_not_saved_children():
		if i.face_value() == value and not i.selected:
			i.selected = true
			return

func reset_and_throw_all():
	for i in self.get_not_saved_children():
		i.reset_and_throw(positive_z)

func unstick():
	for i in self.get_not_saved_children():
		if not i.grounded():
			i.bump()

func all_grounded():
	for i in self.get_not_saved_children():
		if not i.grounded():
			return false
	return true

func get_face_values():
	var values = []
	for i in self.get_not_saved_children():
		if !i.face_value():
			return false
		values.append(i.face_value())
	return values

func get_selected_values():
	var values = []
	for i in self.get_not_saved_children():
		if i.selected:
			values.append(i.face_value())
	return values

func dice_selectable():
	return $"..".settled and $"..".active_player_index == self.player_index

func count_saved():
	var c = 0
	for i in self.get_children():
		c += int(i.saved)
	return c

func save_selected():
	for i in self.get_not_saved_children():
		i.saved = i.selected
		if i.saved:
			var aabb = i.get_node("DieMesh").get_aabb()
			var z
			if self.positive_z:
				z = -1.2
			else:
				z = 1.2
			var save_pos = Vector3(-12.5 + (self.count_saved() * 2.5), aabb.size.y, z)
			i.translation = save_pos
#			i.rotation_degrees.y = 0
