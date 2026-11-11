class_name LevelMap
extends CanvasLayer
signal level_selected(level: int)
signal sound_requested
var root: Control
var scroll: ScrollContainer
var content: Control
var campaign: Progression
var card_buttons: Array[Button] = []
var points := PackedVector2Array()

func _ready() -> void:
	layer = 5
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var backdrop := ColorRect.new()
	backdrop.color = Color("091c24")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)
	scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	content = Control.new()
	content.custom_minimum_size = Vector2(432,2350)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	var banner := TextureRect.new()
	banner.texture = load("res://assets/images/beaver-icon.png")
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	banner.position = Vector2(0,0)
	banner.size = Vector2(432,280)
	content.add_child(banner)
	var shade := ColorRect.new()
	shade.color = Color(0.02,0.07,0.09,0.6)
	shade.position = Vector2(0,220)
	shade.size = Vector2(432,150)
	content.add_child(shade)
	text("BEAVER MAYHEM", Vector2(24,235), 31, Art.GOLD)
	text("THE ROAD HOME", Vector2(26,280), 17, Color("a7d9c8"))
	text("10 CHAPTERS · SAVE YOUR FAMILY", Vector2(26,309), 12, Color("a7d9c8"))
	for i in range(10): points.append(Vector2(216 + sin(i * 1.8) * 66, 2160-i*188))
	content.draw.connect(draw_road)
	for i in range(10): build_card(i+1, points[i])
	var header := PanelContainer.new()
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = 84
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color(0.035,0.10,0.13,0.94)
	header_style.content_margin_left = 24
	header_style.content_margin_top = 20
	header.add_theme_stylebox_override("panel",header_style)
	root.add_child(header)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var heading := Label.new()
	heading.text = "BEAVER MAYHEM / CHAPTERS"
	heading.add_theme_font_size_override("font_size",18)
	heading.add_theme_color_override("font_color",Art.GOLD)
	header.add_child(heading)
	var sound := Button.new()
	sound.text = "♪"
	sound.position = Vector2(376,27)
	sound.size = Vector2(42,42)
	sound.pressed.connect(sound_requested.emit)
	root.add_child(sound)
	var footer := Label.new()
	footer.position = Vector2(20,2280)
	footer.text = "DRAG THE MAP TO EXPLORE  •  PROGRESS SAVES LOCALLY"
	footer.add_theme_font_size_override("font_size",11)
	content.add_child(footer)

func text(value: String, pos: Vector2, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = value
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	content.add_child(label)

func draw_road() -> void:
	content.draw_polyline(points, Color("153a3c"), 32, true)
	content.draw_polyline(points, Color("42766b"), 21, true)
	content.draw_polyline(points, Color("b89b61"), 2, true)
	for i in range(9):
		for step in range(1,7):
			var p: Vector2 = points[i].lerp(points[i+1], step/7.0)
			content.draw_circle(p, 2, Art.GOLD)

func build_card(level: int, center: Vector2) -> void:
	var card := Button.new()
	card.position = center - Vector2(101,70)
	card.size = Vector2(202,140)
	card.clip_contents = true
	card.focus_mode = Control.FOCUS_NONE
	card.pressed.connect(func() -> void: level_selected.emit(level))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("133c3b")
	style.border_color = Art.GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	card.add_theme_stylebox_override("normal",style)
	var hover := style.duplicate()
	hover.bg_color = Color("326556")
	card.add_theme_stylebox_override("hover",hover)
	card.add_theme_stylebox_override("pressed",hover)
	var locked := style.duplicate()
	locked.bg_color = Color("14272e")
	locked.border_color = Color("355158")
	card.add_theme_stylebox_override("disabled",locked)
	content.add_child(card)
	var preview := TextureRect.new()
	preview.texture = load("res://assets/images/level-preview.png") if ResourceLoader.exists("res://assets/images/level-preview.png") else load("res://assets/images/beaver-icon.png")
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview.position = Vector2(8,8)
	preview.size = Vector2(186,80)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.modulate = Color.from_hsv(fmod(0.08 * level,0.15),0.15,0.9)
	card.add_child(preview)
	var caption := Label.new()
	caption.name = "Caption"
	caption.position = Vector2(12,93)
	caption.add_theme_font_size_override("font_size",15)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(caption)
	card_buttons.append(card)

func show_campaign(value: Progression) -> void:
	campaign = value
	root.visible = true
	for i in range(10):
		var button := card_buttons[i]
		button.disabled = i+1 > campaign.unlocked
		button.get_node("Caption").text = "CHAPTER %02d   %s" % [i+1, "LOCKED" if button.disabled else ("✓" if i+1 < campaign.unlocked else "PLAY →")]
		button.modulate = Color(0.48,0.57,0.65) if button.disabled else Color.WHITE
	content.queue_redraw()
	await get_tree().process_frame
	scroll.scroll_vertical = int(points[campaign.selected-1].y - 420)
