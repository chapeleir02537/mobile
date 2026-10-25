extends RefCounted

# Probabilidades (ajuste aqui)
const CHANCE_MUTACAO_RARA := 0.0001  # 0,01% de nascer algo totalmente novo
const CHANCE_COMBINACAO := 0.25      # chance de uma soma coerente entre espécies
# o restante: idêntica a um dos dois pais (50/50)

const SPECIES := {
	"comum": {"nome": "Comum", "cor": Color(0.95, 0.92, 0.85)},
	"agua": {"nome": "Água", "cor": Color(0.35, 0.65, 0.95)},
	"fogo": {"nome": "Fogo", "cor": Color(0.95, 0.40, 0.2)},
	"terra": {"nome": "Terra", "cor": Color(0.55, 0.40, 0.25)},
	"ferro": {"nome": "Ferro", "cor": Color(0.62, 0.65, 0.7)},
	"ferrugem": {"nome": "Ferrugem", "cor": Color(0.72, 0.38, 0.18)},
	"lama": {"nome": "Lama", "cor": Color(0.42, 0.33, 0.2)},
	"vapor": {"nome": "Vapor", "cor": Color(0.82, 0.88, 0.92)},
	"magma": {"nome": "Magma", "cor": Color(0.8, 0.15, 0.1)},
	"dourada": {"nome": "Dourada", "cor": Color(1.0, 0.84, 0.2)},
	"arcoiris": {"nome": "Arco-íris", "cor": Color(0.85, 0.4, 0.9)},
	"cosmica": {"nome": "Cósmica", "cor": Color(0.2, 0.15, 0.45)},
}

# Somas coerentes (chave = pais em ordem alfabética)
const COMBOS := {
	"agua+ferro": "ferrugem",
	"agua+terra": "lama",
	"agua+fogo": "vapor",
	"fogo+terra": "magma",
}

const RARAS := ["dourada", "arcoiris", "cosmica"]
const BASICAS := ["comum", "agua", "fogo", "terra", "ferro"]

static func breed(a: String, b: String) -> String:
	if randf() < CHANCE_MUTACAO_RARA:
		return RARAS[randi() % RARAS.size()]
	if a != b:
		var pair := [a, b]
		pair.sort()
		var key: String = pair[0] + "+" + pair[1]
		if COMBOS.has(key) and randf() < CHANCE_COMBINACAO:
			return COMBOS[key]
	return a if randf() < 0.5 else b
