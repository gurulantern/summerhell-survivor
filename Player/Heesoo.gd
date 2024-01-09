extends CharacterBody2D


@export var hp = 80
@export var maxhp = 80
@onready var anim : AnimatedSprite2D = $AnimatedSprite2D

#Experience
var exp = 0
var exp_level = 1
var collected_exp = 0

#Attacks
var earPick = preload("res://Attack/earPick/ear_pick.tscn")
var fannyPack = preload("res://Attack/fannypack/fanny_pack.tscn")
var gasLight = preload("res://Attack/gaslight/gas_light_path.tscn")

#AttackNodes
@onready var earPickTimer = get_node("%EarPickTimer")
@onready var earPickAttackTimer = get_node("%EarPickAttackTimer")
@onready var fannyPackTimer = get_node("%FannyPackTimer")
@onready var fannyPackAttackTimer = get_node("%FannyPackAttackTimer")
@onready var gasLightTimer = get_node("%GasLightTimer")
@onready var gasLightAttackTimer = get_node("%GasLightAttackTimer")
@onready var gasLightPath = get_node("GasLightPath")

#Upgrades
var collected_upgrades_array = []
var upgrade_options_array = []
var armor = 0
var speed = 80
var spell_cooldown = 0
var spell_size = 0
var additional_attacks = 0

#Ear Pick
var earPick_ammo = 0
var earPick_baseammo = 0
var earPick_attackspeed = 1.8
var earPick_level = 0

#Fanny Pack
var fannyPack_ammo = 0
var fannyPack_baseammo = 0
var fannyPack_attackspeed = 2
var fannyPack_level = 0
var flipped = false

#Gas Light
var gasLight_ammo = 0
var gasLight_baseammo = 0
var gasLight_attackspeed = 2
var gasLight_level = 0

#Enemy Related
var enemy_close = []

#GUI
@onready var exp_bar = get_node("%ExperienceBar")
@onready var level_label = get_node("%LabelLevel")
@onready var level_panel = get_node("%LevelUp")
@onready var upgrade_options = get_node("%UpgradeOptions")
@onready var snd_levelUp = get_node("%snd_levelUp")
@onready var item_options = preload("res://Utility/item_option.tscn")

func _ready():
	anim.play("idle")
	attack()
	set_exp_bar(exp, calculate_exp_cap())


func _physics_process(delta):
	var direction : Vector2 = Input.get_vector("left", "right", "up", "down").normalized()

	if direction: 
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
	
	if velocity.x > 0:
		anim.flip_h = true
	elif velocity.x < 0:
		anim.flip_h = false
		
	if velocity.y != 0 or velocity.x != 0:
		anim.play("walk")	
	else:
		anim.play("idle")
	
	move_and_slide()

func attack():
	if earPick_level > 0:
		earPickTimer.wait_time = earPick_attackspeed * (1 - spell_cooldown)
		if earPickTimer.is_stopped():
			earPickTimer.start()
	if fannyPack_level > 0:
		fannyPackTimer.wait_time = fannyPack_attackspeed * (1 - spell_cooldown)
		if fannyPackTimer.is_stopped():
			fannyPackTimer.start()
	if gasLight_level > 0:
		gasLightTimer.wait_time = gasLight_attackspeed * (1 - spell_cooldown)
		if gasLightTimer.is_stopped():
			gasLightTimer.start()

func _on_hurtbox_hurt(damage, _angle, _knockback):
	hp -= damage
	print(hp)

#Ear Pick Timers 
#Loads ammunition
func _on_ear_pick_timer_timeout():
	earPick_ammo += earPick_baseammo + additional_attacks
	earPickAttackTimer.start()

#Shoots
func _on_ear_pick_attack_timer_timeout():
	if earPick_ammo > 0:
		print("Firing Earpick")
		var earPick_attack = earPick.instantiate()
		earPick_attack.position = global_position
		earPick_attack.target = get_random_target()
		earPick_attack.level = earPick_level
		add_child(earPick_attack)
		earPick_ammo -= 1
		if earPick_ammo > 0:
			earPickAttackTimer.start()
		else:
			earPickAttackTimer.stop()

#Fanny Pack timers
func _on_fanny_pack_timer_timeout():
	fannyPack_ammo += fannyPack_baseammo + additional_attacks
	fannyPackAttackTimer.start()

func _on_fanny_pack_attack_timer_timeout():
	if fannyPack_ammo > 0:
		var fannyPack_attack = fannyPack.instantiate()
		var texture_size = fannyPack_attack.get_node("Sprite2D").texture.get_size()
		fannyPack_attack.level = fannyPack_level
		if flipped:
			fannyPack_attack.flip_sprite()
			fannyPack_attack.position = get_spawn_point(global_position, texture_size, fannyPack_attack.scale_multiplier)
		else:
			fannyPack_attack.position = get_spawn_point(global_position, -texture_size, fannyPack_attack.scale_multiplier)
		add_child(fannyPack_attack)
		fannyPack_ammo -= 1
		if fannyPack_ammo > 0:
			flipped = !flipped
			fannyPackAttackTimer.start()
		else:
			flipped = !flipped
			fannyPackAttackTimer.stop()

func _on_gas_light_timer_timeout():
	gasLight_ammo += gasLight_baseammo + additional_attacks
	gasLightAttackTimer.start()

func _on_gas_light_attack_timer_timeout():
	gasLight_ammo -= 1
	if gasLight_ammo > 0:
		gasLightPath.play_attack()
		gasLightAttackTimer.start()
	else:
		gasLightAttackTimer.stop()

func get_random_target():
	if enemy_close.size() > 0:
		return enemy_close.pick_random().global_position
	else:
		return Vector2.UP

func get_spawn_point(parent_global_position: Vector2, attack_size: Vector2, attack_scale: Vector2) -> Vector2:
	# Calculate the offset to position the weapon's bottom right corner at the center of the parent
	var offset = Vector2(attack_size.x * 1.0 * attack_scale.x, attack_size.y * 0.5 * attack_scale.y)
	# Calculate the spawn position by adding the offset to the parent's global position
	var spawn_position = parent_global_position + offset
	
	return spawn_position


func _on_grab_area_area_entered(area):
	if area.is_in_group("loot"):
		area.target = self

func _on_collect_area_area_entered(area):
	if area.is_in_group("loot"):
		var pentagram_exp = area.collect()
		print("EXP gained: ", pentagram_exp)
		calculate_exp(pentagram_exp)

func calculate_exp(pentagram_exp):
	var exp_required = calculate_exp_cap()
	collected_exp += pentagram_exp
	print(collected_exp)
	if exp + collected_exp >= exp_required:
		collected_exp -= exp_required-exp
		exp_level += 1
		exp = 0
		exp_required = calculate_exp_cap()
		level_up()
	else:
		exp += collected_exp
		collected_exp = 0
	
	set_exp_bar(exp, exp_required)

func calculate_exp_cap():
	var exp_cap = exp_level
	if exp_level < 20:
		exp_cap = exp_level * 5
	elif exp_level < 40:
		exp_cap = 95 * (exp_level-19)*8
	else:
		exp_cap = 255 + (exp_level-39)*12
	return exp_cap

func set_exp_bar(set_value = 1, set_max_value = 100):
	exp_bar.value = set_value
	exp_bar.max_value = set_max_value

func level_up():
	snd_levelUp.play()
	var tween = level_panel.create_tween()
	tween.tween_property(level_panel, "position:y", 50, 0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.play()
	level_panel.visible = true
	var options = 0
	var options_max = 3
	while options < options_max:
		var option_choice = item_options.instantiate()
		option_choice.item = get_random_item()
		upgrade_options.add_child(option_choice)
		options += 1
	get_tree().paused = true
	level_label.text = str("Lvl ", exp_level)

func upgrade_heesoo(upgrade):
	match upgrade:
		"earpick1":
			earPick_level = 1
			earPick_baseammo += 1
		"earpick2":
			earPick_level = 2
			earPick_baseammo += 1
		"earpick3":
			earPick_level = 3
		"earpick4":
			earPick_level = 4
			earPick_baseammo += 2
		"fannypack1":
			fannyPack_level = 1
			fannyPack_baseammo = 1
		"fannypack2":
			fannyPack_level = 2
			fannyPack_attackspeed -= 0.5
		"fannypack3":
			fannyPack_level = 3
			fannyPack_baseammo += 1
		"fannypack4":
			fannyPack_level = 4
			fannyPack_baseammo += 1
			fannyPack_attackspeed -= 0.5
		"gaslight1":
			gasLightPath.activate()
		"gaslight2":
			gasLightPath.amount += 1
			gasLightPath.activate()
		"gaslight3":
			gasLightPath.amount += 1
			gasLightPath.activate()
		"gaslight4":
			gasLightPath.amount += 1
			gasLightPath.activate()
		"clothes1", "clothes2", "clothes3", "clothes4":
			armor += 
		"coffee1", "coffee2", "coffee3", "coffee4":
			speed += 20 
		"book1", "book2", "book3", "book4":
			spell_size += 0.10
		"podcast1", "podcast2", "podcast3", "podcast4":
			spell_cooldown += 0.05
		"glasses1", "glasses2":
			additional_attacks += 1
		"sashimi":
			hp += 20
			hp = clamp(hp, 0, maxhp)
	
	var option_children = upgrade_options.get_children()
	for i in option_children:
		i.queue_free()
	upgrade_options_array.clear()
	collected_upgrades_array.append(upgrade)
	level_panel.visible = false
	level_panel.position = Vector2(220, 400)
	get_tree().paused = false
	calculate_exp(0) #Recursive call for remainder exp

func get_random_item():
	var db_list = []
	for i in UpgradeDb.UPGRADES:
		if i in collected_upgrades_array: 
			pass
		elif i in upgrade_options_array:
			pass
		elif UpgradeDb.UPGRADES[i]["type"] == "item":
			pass
		elif UpgradeDb.UPGRADES[i]["prerequisite"].size() > 0:
			for n in UpgradeDb.UPGRADES[i]["prerequisite"]:
				if not n in collected_upgrades_array:
					pass
				else: 
					db_list.append(i) 
		else:
			db_list.append(i)
	if db_list.size() > 0:
		var random_item = db_list.pick_random()
		upgrade_options_array.append(random_item)
		return random_item
	else:
		return null
