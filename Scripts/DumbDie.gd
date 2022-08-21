extends Node


func _on_body_entered(_body):
	if self.linear_velocity.length_squared() + self.angular_velocity.length_squared() > 3:
#		$RandomSFX.unit_db = 1 * max(5, min(50, (self.linear_velocity.length_squared() + self.angular_velocity.length_squared()) / 30))
		$RandomSFX.play()
