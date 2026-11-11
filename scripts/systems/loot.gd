class_name LootSystem
extends Node3D
signal collected(amount: int, pos: Vector3)
var coins: Array[Dictionary] = []

func drop(pos: Vector2, reward: int) -> void:
	if coins.size() >= int(Rules.config.loot_cap): return
	# Three physical pieces split the exact reward without rounding profit.
	for i in range(3):
		var amount := reward / 3 + (1 if i < reward % 3 else 0)
		var visual := Node3D.new()
		add_child(visual)
		var mesh := Art.cylinder(visual, Vector3.ZERO, 0.22, 0.08, Art.GOLD)
		mesh.rotation.x = PI / 2
		coins.append({"pos": pos + Vector2((i-1) * 0.26, 0), "visual": visual, "amount": amount, "age": 0.0})

func tick(delta: float, player_x: float) -> void:
	for coin in coins.duplicate():
		coin.age += delta
		coin.pos.y += float(Rules.config.run_speed) * delta
		var offset: Vector2 = Vector2(player_x,0) - coin.pos
		if offset.length() < float(Rules.config.loot_radius):
			coin.pos = coin.pos.move_toward(Vector2(player_x, 0), delta * 7.0)
		if offset.length() < 0.55:
			collected.emit(coin.amount, Vector3(coin.pos.x, 0.8, coin.pos.y))
			remove(coin)
			continue
		coin.visual.position = Vector3(coin.pos.x, 0.5 + maxf(0, sin(minf(coin.age, 0.7) / 0.7 * PI)) * 1.1, coin.pos.y)
		coin.visual.rotation.y += delta * 3.0
		if coin.pos.y > 5: remove(coin)

func remove(coin: Dictionary) -> void:
	coins.erase(coin)
	coin.visual.queue_free()

func clear() -> void:
	for coin in coins.duplicate(): remove(coin)
