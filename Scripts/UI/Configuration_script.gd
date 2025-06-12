extends Control

@onready var option_screen = $Screen_Option
@onready var option_resolution = $Resolution_Option
@onready var slider_volume = $Volume_Slider

var resolutions = {
	"720x576": Vector2i(720, 576),
	"1280x720": Vector2i(1280, 720),
	"1920x1080": Vector2i(1920, 1080),
	"2560x1440": Vector2i(2560, 1440)
}

func _ready() -> void:
	# Opciones de pantalla
	option_screen.clear()
	option_screen.add_item("Ventana")
	option_screen.add_item("Pantalla completa")
	option_screen.add_item("Sin bordes")
	option_screen.connect("item_selected", _on_option_screen_selected)

	# Resoluciones
	option_resolution.clear()
	for res_name in resolutions.keys():
		option_resolution.add_item(res_name)
	option_resolution.connect("item_selected", _on_option_resolution_selected)

	# Slider de volumen
	slider_volume.connect("value_changed", _on_slider_volume_changed)

	# Cargar datos actuales desde ConfigurationManager
	_load_current_settings()

func _load_current_settings() -> void:
	# Volumen
	slider_volume.value = ConfigurationManager.volume

	# Modo de pantalla
	select_option_by_text(option_screen, ConfigurationManager.screen)
	ConfigurationManager.set_screen_mode(ConfigurationManager.screen)

	# Resolución
	select_option_by_text(option_resolution, ConfigurationManager.resolution)
	ConfigurationManager.set_resolution(ConfigurationManager.resolution)


func _on_slider_volume_changed(value: float) -> void:
	ConfigurationManager.set_volume(value)
	ConfigurationManager.save_settings()

func _on_option_screen_selected(index: int) -> void:
	var mode = option_screen.get_item_text(index)
	ConfigurationManager.set_screen_mode(mode)
	ConfigurationManager.save_settings()

func _on_option_resolution_selected(index: int) -> void:
	var res_text = option_resolution.get_item_text(index)
	ConfigurationManager.set_resolution(res_text)
	ConfigurationManager.set_resolution(res_text)
	ConfigurationManager.save_settings()

func select_option_by_text(option_button: OptionButton, text: String) -> void:
	for i in range(option_button.item_count):
		if option_button.get_item_text(i) == text:
			option_button.select(i)
			break

func _on_return_btn_pressed() -> void:
	visible = false
	$"../Menu_default".visible = true
