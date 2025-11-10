class_name Menu extends Control

const CONFIG_FILE_PATH: String = "user://settings.cfg"
const MUSIC_BUS_INDEX: int = 2
const SFX_BUS_INDEX: int = 1

@onready var language_option_button: OptionButton = %LanguageOptionButton
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var button: Button = %Button


func _ready() -> void:
	# Load saved preferences
	load_preferences()

	# Connect signals
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	language_option_button.item_selected.connect(_on_language_changed)
	button.pressed.connect(_on_continue_pressed)

	# Set up sliders (0-100 range, default to 100)
	music_slider.min_value = 0
	music_slider.max_value = 100
	sfx_slider.min_value = 0
	sfx_slider.max_value = 100

	button.grab_focus.call_deferred()


func load_preferences() -> void:
	var config := ConfigFile.new()
	var err := config.load(CONFIG_FILE_PATH)

	if err == OK:
		# Load music volume
		var music_volume: float = config.get_value("audio", "music_volume", 100.0)
		music_slider.value = music_volume
		set_bus_volume(MUSIC_BUS_INDEX, music_volume)

		# Load SFX volume
		var sfx_volume: float = config.get_value("audio", "sfx_volume", 100.0)
		sfx_slider.value = sfx_volume
		set_bus_volume(SFX_BUS_INDEX, sfx_volume)

		# Load language
		var saved_language: String = config.get_value("game", "language", "")
		if saved_language == "fr":
			language_option_button.selected = 0
			TranslationServer.set_locale("fr")
		elif saved_language == "en":
			language_option_button.selected = 1
			TranslationServer.set_locale("en")
		else:
			# First time - detect from system locale
			detect_and_set_language()
	else:
		# First time - no config file exists
		music_slider.value = 100
		sfx_slider.value = 100
		set_bus_volume(MUSIC_BUS_INDEX, 100)
		set_bus_volume(SFX_BUS_INDEX, 100)
		detect_and_set_language()


func detect_and_set_language() -> void:
	var locale := OS.get_locale_language()
	if locale == "fr":
		language_option_button.selected = 0
		TranslationServer.set_locale("fr")
	else:
		# Default to English for anything else
		language_option_button.selected = 1
		TranslationServer.set_locale("en")


func save_preferences() -> void:
	var config := ConfigFile.new()

	# Save audio volumes
	config.set_value("audio", "music_volume", music_slider.value)
	config.set_value("audio", "sfx_volume", sfx_slider.value)

	# Save language
	var language := "en" if language_option_button.selected == 1 else "fr"
	config.set_value("game", "language", language)

	config.save(CONFIG_FILE_PATH)


func set_bus_volume(bus_index: int, value: float) -> void:
	var db := linear_to_db(value / 100.0)
	if value == 0:
		db = -80  # Effectively mute
	AudioServer.set_bus_volume_db(bus_index, db)


func _on_music_slider_changed(value: float) -> void:
	set_bus_volume(MUSIC_BUS_INDEX, value)


func _on_sfx_slider_changed(value: float) -> void:
	set_bus_volume(SFX_BUS_INDEX, value)


func _on_language_changed(index: int) -> void:
	if index == 0:
		TranslationServer.set_locale("fr")
	else:
		TranslationServer.set_locale("en")


func _on_continue_pressed() -> void:
	# Save preferences before continuing
	save_preferences()

	# Get the game node (parent of HUD which contains this menu)
	var hud := get_parent()
	if hud:
		var game := hud.get_parent()
		if game and game.has_method("toggle_menu"):
			game.call("toggle_menu")
