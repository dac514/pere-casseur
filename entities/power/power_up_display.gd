# Attach this script to each HUD/PowerUps/PowerX node
# Set the tier_number in the editor inspector:
# Power1 -> tier_number = 1 (Amazon Fulfillment Deal)
# Power2 -> tier_number = 2 (Scab Post Express)
# Power3 -> tier_number = 3 (Oil Baron's Pact)
# ...
# Power10 -> tier_number = 10 (World Bank Bailout)

extends Control

@export var tier_number: int = 1  # Default to first power-up

@onready var progress_bar: ProgressBar = $MarginContainer/HealthBar
@onready var sprite: Node = self  # Will apply effects to entire Control node


func _ready() -> void:
	# Connect to GameManager signals
	GameManager.tier_unlocked.connect(_on_tier_unlocked)
	GameManager.tier_progress_updated.connect(_on_tier_progress_updated)

	# Start locked: dark/shadowed appearance
	_set_locked_state()
	progress_bar.value = 0


func _on_tier_unlocked(tier_number_unlocked: int, _tier_name: String) -> void:
	if tier_number_unlocked == tier_number:
		# Unlock: full color and visibility
		_set_unlocked_state()
		progress_bar.value = 100
		_play_unlock_animation()


func _on_tier_progress_updated(tier_number_updated: int, progress: float) -> void:
	# Check if this is the currently active tier being filled
	# When current_tier = 0, we're filling toward tier 1 (Amazon/Power1)
	# When current_tier = 1, we're filling toward tier 2 (Scab/Power2)
	if tier_number_updated == tier_number - 1:
		# Currently filling up toward unlock
		progress_bar.value = progress
		_set_filling_state()
	elif tier_number_updated >= tier_number:
		# Already unlocked
		progress_bar.value = 100
		_set_unlocked_state()
	else:
		# Not yet ready to unlock (still locked)
		progress_bar.value = 0
		_set_locked_state()


func _set_locked_state() -> void:
	# Dark shadow version
	modulate = Color(0.2, 0.2, 0.2, 0.5)  # Very dark gray, semi-transparent


func _set_filling_state() -> void:
	# Partially visible while filling
	modulate = Color(0.7, 0.7, 0.7, 0.8)  # Lighter gray, more visible


func _set_unlocked_state() -> void:
	# Fully visible with full color
	modulate = Color(1.0, 1.0, 1.0, 1.0)  # Full brightness and opacity


func _play_unlock_animation() -> void:
	# Simple scale bounce animation when unlocking
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.3)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
