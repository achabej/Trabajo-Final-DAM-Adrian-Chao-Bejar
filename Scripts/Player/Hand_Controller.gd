extends Node3D

var weapons: Array = [] 
var current_weapon_index: int = -1 
var last_weapon_index: int = -1 

func _ready():
	_update_list()

func _update_list():
	weapons = get_children()
	if weapons.size() > 0:
		equip_weapon(0)  

func _input(event):
	if event is InputEventKey and event.pressed:
		if Input.is_action_just_pressed("Item_1"):
			toggle_or_equip_weapon(0)
		elif Input.is_action_just_pressed("Item_2"):
			toggle_or_equip_weapon(1)
		elif Input.is_action_just_pressed("Item_3"):
			toggle_or_equip_weapon(2)

# Dependiendo si el arma actual es la misma que el index, cambiara la visibilidad o cambiara de objeto
func toggle_or_equip_weapon(index: int):
	if current_weapon_index == index:
		toggle_weapon()  # Si el arma ya está equipada, se deselecciona
	else:
		equip_weapon(index)  # Si no, se equipa el arma seleccionada

# Equipa el objeto del indice pasado como parametro
func equip_weapon(index: int):
	if index >= 0 and index < weapons.size():
		if current_weapon_index != -1:
			weapons[current_weapon_index].visible = false
		
		weapons[index].visible = true
		last_weapon_index = current_weapon_index  
		current_weapon_index = index

# Cambia la visibilidad del objeto actual cuando se llama
func toggle_weapon():
	if current_weapon_index != -1:
		weapons[current_weapon_index].visible = false
		last_weapon_index = current_weapon_index
		current_weapon_index = -1
	elif last_weapon_index != -1:
		equip_weapon(last_weapon_index)

# Obtiene el objeto actual
func get_current_weapon():
	if current_weapon_index != -1 and current_weapon_index < weapons.size():
		return weapons[current_weapon_index]
	return null

# Función para ocultar el arma
func hide_weapon():
	if current_weapon_index != -1 and current_weapon_index < weapons.size():
		weapons[current_weapon_index].visible = false  # Oculta el arma equipada

# Función para mostrar el arma
func show_weapon():
	if last_weapon_index != -1 and last_weapon_index < weapons.size():
		weapons[last_weapon_index].visible = true  # Muestra el arma equipada
