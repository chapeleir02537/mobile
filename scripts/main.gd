extends Node2D

const Gen = preload("res://scripts/genetics.gd")

const ADULT := 3
const MAX_CHICKENS := 8
const MAX_EGGS := 4
const GROW_TIME := 8.0
const HATCH_TIME := 15.0
const COOP := Rect2(30, 560, 660, 330)
const PLOT_SIZE := Vector2(190, 130)

class Chick:
	var species: String
	var growth := 0
	var pos: Vector2
	var target: Vector2
	var wait := 0.0

var chickens: Array = []
var eggs: Array = []        # {sp, t}
var plots: Array = []       # {state: 0 vazio/1 crescendo/2 pronto, t}
var selected: Array = []
var coins := 10
var seeds := 5
var grain := 0
var discovered := {}
var msg := "Toque numa galinha para selecionar."
var show_dex := false
var msg_timer := 0.0

var info: Label
var dex_label: Label

func _ready() -> void:
	randomize()
	for i in 6:
		plots.append({"state": 0, "t": 0.0})
	_spawn("comum", ADULT)
	_spawn("agua", ADULT)
	_build_ui()

func _spawn(sp: String, growth: int) -> void:
	var c := Chick.new()
	c.species = sp
	c.growth = growth
	c.pos = _rand_in_coop()
	c.target = c.pos
	chickens.append(c)
	discovered[sp] = true

func _rand_in_coop() -> Vector2:
	return Vector2(randf_range(COOP.position.x + 40, COOP.end.x - 40),
		randf_range(COOP.position.y + 70, COOP.end.y - 40))

func _plot_rect(i: int) -> Rect2:
	return Rect2(30 + (i % 3) * 215, 150 + (i / 3) * 155, PLOT_SIZE.x, PLOT_SIZE.y)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	info = Label.new()
	info.position = Vector2(30, 905)
	info.size = Vector2(660, 80)
	info.add_theme_font_size_override("font_size", 28)
	layer.add_child(info)
	dex_label = Label.new()
	dex_label.position = Vector2(60, 200)
	dex_label.size = Vector2(600, 700)
	dex_label.add_theme_font_size_override("font_size", 30)
	dex_label.visible = false
	layer.add_child(dex_label)
	var defs := [
		["Alimentar", _on_feed], ["Cruzar", _on_breed], ["Vender", _on_sell],
		["Comprar sementes", _on_buy], ["Coleção", _on_dex], ["Dormir", _on_sleep],
	]
	for i in defs.size():
		var b := Button.new()
		b.text = defs[i][0]
		b.position = Vector2(30 + (i % 3) * 225, 1010 + (i / 3) * 110)
		b.size = Vector2(210, 95)
		b.add_theme_font_size_override("font_size", 26)
		b.pressed.connect(defs[i][1])
		layer.add_child(b)

func _say(t: String) -> void:
	msg = t
	msg_timer = 4.0

func _on_feed() -> void:
	if selected.is_empty():
		return _say("Selecione uma galinha primeiro.")
	var c: Chick = selected[0]
	if c.growth >= ADULT:
		return _say("Ela já é adulta.")
	if grain < 1:
		return _say("Sem alimento! Plante e colha.")
	grain -= 1
	c.growth += 1
	_say("Cresceu! (%d/%d)" % [c.growth, ADULT])

func _on_breed() -> void:
	if selected.size() != 2:
		return _say("Selecione 2 galinhas adultas.")
	var a: Chick = selected[0]
	var b: Chick = selected[1]
	if a.growth < ADULT or b.growth < ADULT:
		return _say("As duas precisam ser adultas.")
	if eggs.size() >= MAX_EGGS:
		return _say("Incubadora cheia.")
	eggs.append({"sp": Gen.breed(a.species, b.species), "t": HATCH_TIME})
	selected.clear()
	_say("Ovo posto para chocar!")

func _on_sell() -> void:
	if selected.is_empty():
		return _say("Selecione uma galinha para vender.")
	var c: Chick = selected[0]
	var price := 10 + (20 if c.species in Gen.RARAS else (5 if not c.species in Gen.BASICAS else 0))
	coins += price
	chickens.erase(c)
	selected.clear()
	_say("Vendida por %d moedas." % price)

func _on_buy() -> void:
	if coins < 5:
		return _say("Precisa de 5 moedas.")
	coins -= 5
	seeds += 3
	_say("+3 sementes.")

func _on_dex() -> void:
	show_dex = not show_dex

func _on_sleep() -> void:
	for p in plots:
		if p.state == 1:
			p.t = max(p.t - 4.0, 0.0)
	for e in eggs:
		e.t = max(e.t - 4.0, 0.0)
	_say("Você dormiu. Tudo avançou um pouco.")

func _input(event: InputEvent) -> void:
	if show_dex or not (event is InputEventMouseButton and event.pressed):
		return
	var p: Vector2 = event.position
	if p.y > 1000:
		return
	for i in plots.size():
		if _plot_rect(i).has_point(p):
			_tap_plot(i)
			return
	for c in chickens:
		if c.pos.distance_to(p) < 45.0:
			if c in selected:
				selected.erase(c)
			else:
				selected.append(c)
				if selected.size() > 2:
					selected.pop_front()
			return

func _tap_plot(i: int) -> void:
	var pl: Dictionary = plots[i]
	if pl.state == 0:
		if seeds < 1:
			return _say("Sem sementes.")
		seeds -= 1
		pl.state = 1
		pl.t = GROW_TIME
	elif pl.state == 2:
		pl.state = 0
		grain += 2
		_say("+2 alimento")

func _process(delta: float) -> void:
	msg_timer -= delta
	for pl in plots:
		if pl.state == 1:
			pl.t -= delta
			if pl.t <= 0.0:
				pl.state = 2
	for e in eggs.duplicate():
		e.t -= delta
		if e.t <= 0.0 and chickens.size() < MAX_CHICKENS:
			eggs.erase(e)
			var new_sp := not discovered.has(e.sp)
			_spawn(e.sp, 0)
			_say(("NOVA ESPÉCIE: " if new_sp else "Nasceu: ") + Gen.SPECIES[e.sp].nome + "!")
	for c in chickens:
		c.wait -= delta
		if c.wait <= 0.0 and c.pos.distance_to(c.target) < 5.0:
			c.target = _rand_in_coop()
			c.wait = randf_range(1.0, 3.0)
		c.pos = c.pos.move_toward(c.target, 40.0 * delta)
	info.text = "Moedas %d   Sementes %d   Alimento %d\n%s" % [coins, seeds, grain, msg if msg_timer > 0.0 else "Casa: guarda seus itens."]
	dex_label.visible = show_dex
	if show_dex:
		var t := "COLEÇÃO (%d/%d)\n\n" % [discovered.size(), Gen.SPECIES.size()]
		for k in Gen.SPECIES:
			t += ("• " + Gen.SPECIES[k].nome if discovered.has(k) else "• ???") + "\n"
		dex_label.text = t
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, 720, 1280), Color(0.35, 0.62, 0.3))
	# casa
	draw_rect(Rect2(30, 20, 200, 100), Color(0.75, 0.5, 0.35))
	draw_colored_polygon(PackedVector2Array([Vector2(20, 20), Vector2(130, -10), Vector2(240, 20)]), Color(0.6, 0.2, 0.2))
	draw_string(font, Vector2(75, 85), "Casa", HORIZONTAL_ALIGNMENT_LEFT, -1, 28)
	# plantações
	for i in plots.size():
		var r := _plot_rect(i)
		var pl: Dictionary = plots[i]
		var col := Color(0.45, 0.3, 0.18)
		if pl.state == 1:
			col = col.lerp(Color(0.3, 0.7, 0.25), 1.0 - pl.t / GROW_TIME)
		elif pl.state == 2:
			col = Color(0.9, 0.75, 0.2)
		draw_rect(r, col)
		draw_rect(r, Color(0.25, 0.15, 0.08), false, 4.0)
		var label := ["vazio", "crescendo", "COLHER"][pl.state]
		draw_string(font, r.position + Vector2(20, 75), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 28)
	# galinheiro
	draw_rect(COOP, Color(0.7, 0.55, 0.35))
	draw_rect(COOP, Color(0.4, 0.28, 0.15), false, 6.0)
	draw_string(font, COOP.position + Vector2(15, 35), "Galinheiro", HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
	for i in eggs.size():
		var ep := COOP.position + Vector2(300 + i * 90, 28)
		draw_circle(ep, 16, Color(1, 0.97, 0.9))
		draw_string(font, ep + Vector2(-12, 40), "%ds" % ceil(eggs[i].t), HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
	var sorted := chickens.duplicate()
	sorted.sort_custom(func(a, b): return a.pos.y < b.pos.y)
	for c in sorted:
		var rad := 16.0 + c.growth * 6.0
		var dir := signf(c.target.x - c.pos.x)
		if dir == 0.0:
			dir = 1.0
		if c in selected:
			draw_arc(c.pos, rad + 10.0, 0, TAU, 32, Color(1, 1, 0), 4.0)
		draw_circle(c.pos, rad, Gen.SPECIES[c.species].cor)
		draw_circle(c.pos + Vector2(dir * rad * 0.7, -rad * 0.6), rad * 0.45, Gen.SPECIES[c.species].cor)
		draw_colored_polygon(PackedVector2Array([
			c.pos + Vector2(dir * rad * 1.1, -rad * 0.6),
			c.pos + Vector2(dir * rad * 1.5, -rad * 0.5),
			c.pos + Vector2(dir * rad * 1.1, -rad * 0.4)]), Color(1, 0.65, 0.1))
		draw_string(font, c.pos + Vector2(-30, rad + 24), Gen.SPECIES[c.species].nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
