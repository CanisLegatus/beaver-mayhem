class_name GameHUD
extends CanvasLayer
signal map_requested
signal next_requested
signal skip_requested
signal start_requested
signal restart_requested
signal pause_requested
signal sound_requested
signal purchase_requested(item: String)
signal cycle_requested
var top_panel: Control
var bottom_panel: Control
var root: Control
var hp_label: Label
var money_label: Label
var progress: ProgressBar
var alert: Label
var message: Label
var math_preview: Label
var boss_label: Label
var boss_bar: ProgressBar
var heat_label: Label
var weapon_button: Button
var buttons: Dictionary = {}
var overlay: PanelContainer
var overlay_title: Label
var overlay_text: Label
var play_button: Button
var restart_button: Button
var flash: ColorRect
var notice_time := 0.0
var state := "menu"
var sound_button: Button
var skip_button: Button
var cinematic_caption: Label

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme := Theme.new()
	theme.default_font_size = 16
	for type in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("214b48") if type != "disabled" else Color("2c4242")
		if type == "hover": style.bg_color = Color("356b5e")
		if type == "pressed": style.bg_color = Color("8e6336")
		style.set_corner_radius_all(12)
		style.content_margin_left = 9
		style.content_margin_right = 9
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		style.border_color = Color("4d8c78")
		style.set_border_width_all(1)
		theme.set_stylebox(type, "Button", style)
	theme.set_color("font_color", "Button", Color("fff0cf"))
	theme.set_color("font_disabled_color", "Button", Color("78958b"))
	root.theme = theme
	var top := VBoxContainer.new()
	top_panel = top
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 16
	top.offset_right = -16
	top.offset_top = 28
	top.add_theme_constant_override("separation", 6)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	var title := make_label("BEAVER / MAYHEM", 14, Art.GOLD)
	top.add_child(title)
	var row := HBoxContainer.new()
	top.add_child(row)
	hp_label = make_label("♥ 100", 23, Art.MINT)
	hp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(hp_label)
	money_label = make_label("$40", 27, Art.GOLD)
	row.add_child(money_label)
	sound_button = make_button("♪", sound_requested.emit)
	row.add_child(sound_button)
	row.add_child(make_button("Ⅱ", pause_requested.emit))
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 8
	progress.show_percentage = false
	top.add_child(progress)
	alert = make_label("", 16, Color("ff876b"))
	top.add_child(alert)
	boss_label = make_label("", 20, Art.GOLD)
	top.add_child(boss_label)
	boss_bar = ProgressBar.new()
	boss_bar.show_percentage = false
	boss_bar.custom_minimum_size.y = 12
	boss_bar.visible = false
	top.add_child(boss_bar)
	math_preview = make_label("", 19, Art.GOLD)
	math_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	math_preview.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	math_preview.offset_top = 156
	root.add_child(math_preview)
	message = make_label("", 19, Color("fff3ce"))
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	message.offset_top = 211
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(message)
	var bottom := VBoxContainer.new()
	bottom_panel = bottom
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 12
	bottom.offset_right = -12
	bottom.offset_top = -184
	bottom.offset_bottom = -24
	bottom.add_theme_constant_override("separation", 6)
	root.add_child(bottom)
	heat_label = make_label("DRAG TO DODGE • SHOOT AUTOMATICALLY", 12, Color("fff0ce"))
	heat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(heat_label)
	var upgrades := HBoxContainer.new()
	bottom.add_child(upgrades)
	for key in ["damage", "rate"]:
		var button := make_button(key, func() -> void: purchase_requested.emit(key))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		upgrades.add_child(button)
		buttons[key] = button
	weapon_button = make_button("LOG ↻", cycle_requested.emit)
	upgrades.add_child(weapon_button)
	var weapons := HBoxContainer.new()
	bottom.add_child(weapons)
	for key in ["fan", "heavy", "twin", "laser"]:
		var button := make_button(key.to_upper(), func() -> void: purchase_requested.emit(key))
		button.add_theme_font_size_override("font_size", 13)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		weapons.add_child(button)
		buttons[key] = button
	var hint := make_label("OUTER LANES SKIP MATH • KEEP A CASH RESERVE", 10, Color("c4d7c0"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(hint)
	flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(1,0.15,0.05,0)
	root.add_child(flash)
	skip_button = make_button("SKIP STORY  →", skip_requested.emit)
	skip_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_button.offset_left = -164
	skip_button.offset_top = -94
	skip_button.offset_right = -16
	skip_button.offset_bottom = -44
	root.add_child(skip_button)
	cinematic_caption = make_label("THEIR HOME. HIS PROMISE.\nHold the dam. I will stop them.",21,Color("fff1cb"))
	cinematic_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cinematic_caption.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	cinematic_caption.offset_top = 65
	root.add_child(cinematic_caption)
	build_overlay()
	apply_safe_area()
	get_viewport().size_changed.connect(apply_safe_area)

func make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("152e2d"))
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(44,44)
	button.pressed.connect(callback)
	button.focus_mode = Control.FOCUS_NONE
	return button

func build_overlay() -> void:
	overlay = PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	overlay.offset_left = -194
	overlay.offset_right = 194
	overlay.offset_top = -215
	overlay.offset_bottom = 200
	var style := StyleBoxFlat.new()
	style.bg_color = Color("123b36")
	style.set_corner_radius_all(24)
	style.set_border_width_all(2)
	style.border_color = Art.MINT
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 28
	style.content_margin_bottom = 24
	overlay.add_theme_stylebox_override("panel", style)
	root.add_child(overlay)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	overlay.add_child(column)
	var kicker := make_label("REVENGE OF THE FOREST", 14, Art.MINT)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(kicker)
	overlay_title = make_label("BEAVER\nMAYHEM", 43, Art.GOLD)
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(overlay_title)
	overlay_text = make_label("", 16, Color("e6e5ca"))
	overlay_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(overlay_text)
	play_button = make_button("DEFEND THE FOREST  →", func() -> void:
		if state == "paused": pause_requested.emit()
		elif state == "victory": next_requested.emit()
		else: start_requested.emit())
	column.add_child(play_button)
	restart_button = make_button("PLAY AGAIN  ↻", restart_requested.emit)
	column.add_child(restart_button)
	column.add_child(make_button("LEVEL MAP", map_requested.emit))
	set_state("menu")

func set_state(value: String) -> void:
	state = value
	top_panel.visible = value != "cinematic"
	bottom_panel.visible = value != "cinematic"
	overlay.visible = value not in ["playing","cinematic"]
	skip_button.visible = value == "cinematic"
	cinematic_caption.visible = value == "cinematic"
	play_button.visible = value in ["menu", "paused","victory"]
	restart_button.visible = value in ["victory", "game_over", "paused"]
	play_button.text = "RESUME  →" if value == "paused" else ("NEXT CHAPTER  →" if value == "victory" else "DEFEND THE FOREST  →")
	match value:
		"menu":
			overlay_title.text = "BEAVER\nMAYHEM"
			overlay_text.text = "Drag to dodge. Logs fly straight.\nCollect cash. Solve the gates.\nUpgrade while running.\nSurvive the road. Stop the dozer."
		"paused":
			overlay_title.text = "BREATHER"
			overlay_text.text = "The forest can wait a moment."
		"victory":
			overlay_title.text = "FOREST\nSAVED!"
			overlay_text.text = "One beaver. One very expensive wreck."
		"game_over":
			overlay_title.text = "TIMBER!"
			overlay_text.text = "Keep moving, collect cash,\nand prepare for the bulldozer."

func refresh(health: Health, economy: Economy, seconds: float, boss: Dictionary, combat: PlayerCombat) -> void:
	hp_label.text = "HP %d" % ceili(health.hp)
	money_label.text = "$%d" % economy.money
	money_label.modulate = Color("ff7961") if economy.money < 0 else Color.WHITE
	progress.value = minf(100, seconds / float(Rules.config.run_seconds) * 100)
	alert.text = "BANKRUPTCY ALERT  •  SEIZURE IN %.1fs" % (10.0 - economy.debt_time) if economy.money < 0 else "FOREST ROAD  /  %03d : %d  •  %.0f m/s" % [mini(int(Rules.config.run_seconds), int(seconds)),int(Rules.config.run_seconds),Rules.run_speed(seconds)]
	alert.modulate.a = (0.65 + 0.35 * sin(seconds * 7)) if economy.money < 0 else 1.0
	for kind in ["damage", "rate"]:
		var level := economy.damage_level if kind == "damage" else economy.rate_level
		var cost := Rules.upgrade_cost(kind, level)
		buttons[kind].text = ("DMG" if kind == "damage" else "RATE") + " %d/4\n" % level + ("MAX" if cost < 0 else "$%d" % cost)
		buttons[kind].disabled = state != "playing" or cost < 0 or economy.money < cost
	for kind in ["fan", "heavy", "twin", "laser"]:
		var owned: bool = kind in economy.owned
		buttons[kind].text = kind.to_upper() + ("\n✓" if owned else "\n$%d" % int(Rules.config.weapon_prices[kind]))
		buttons[kind].disabled = state != "playing" or (not owned and economy.money < int(Rules.config.weapon_prices[kind]))
	weapon_button.text = economy.active.to_upper() + "\n↻"
	weapon_button.disabled = state != "playing"
	boss_bar.visible = not boss.is_empty() and not boss.health.dead
	boss_label.text = "DEFORESTATOR  /  %d HP" % ceili(boss.health.hp) if boss_bar.visible else ""
	if boss_bar.visible:
		boss_bar.max_value = boss.health.maximum
		boss_bar.value = boss.health.hp
	heat_label.text = ("OVERHEATED • COOLING" if combat.overheated else "LASER HEAT %d%%" % int(combat.heat * 100)) if economy.active == "laser" else "DRAG TO DODGE • SHOOT AUTOMATICALLY"
	sound_button.text = "×♪" if AudioServer.is_bus_mute(0) else "♪"

func notify(text: String) -> void:
	message.text = text
	notice_time = 2.3

func tick(delta: float) -> void:
	notice_time = maxf(0, notice_time - delta)
	message.visible = notice_time > 0 and state == "playing"
	flash.color.a = move_toward(flash.color.a, 0, delta * 1.4)

func damage_flash() -> void: flash.color.a = 0.3

func apply_safe_area() -> void:
	if OS.get_name() != "Android": return
	var safe := DisplayServer.get_display_safe_area()
	var screen := DisplayServer.screen_get_size()
	var scale_factor := root.size.y / maxf(1, screen.y)
	root.offset_top = maxf(0, safe.position.y * scale_factor)
	root.offset_bottom = -maxf(0, (screen.y - safe.end.y) * scale_factor)

func show_math(groups: Array[Dictionary], seconds: float = 0.0) -> void:
	math_preview.text = ""
	if state != "playing" or groups.is_empty(): return
	var group: Dictionary = groups[0]
	if group.used: return
	var problem: Dictionary = group.problem
	math_preview.text = problem.expression + "   [%.1fs]" % maxf(0.0, -group.z / Rules.run_speed(seconds)) + "\n" + "  %s   /   %s   /   %s" % problem.choices
