## Tests básicos para LlamaInterface
## Ejecutar desde editor: Abrir tests/test_scene.tscn y presionar F6
## Ejecutar headless: godot --headless --path "." --script res://tests/test_llama_interface.gd
extends Node


## Si true, cierra Godot al terminar (para CI/headless)
@export var auto_quit: bool = false

var _tests_passed: int = 0
var _tests_failed: int = 0
var _current_test: String = ""


func _ready() -> void:
	# Detectar si estamos en modo headless
	if DisplayServer.get_name() == "headless":
		auto_quit = true

	print("\n" + "=".repeat(60))
	print("  LlamaInterface - Tests Básicos")
	print("=".repeat(60) + "\n")

	run_all_tests()

	print("\n" + "=".repeat(60))
	if _tests_failed == 0:
		print("  Resultados: %d passed, %d failed" % [_tests_passed, _tests_failed])
	else:
		print("  Resultados: %d passed, %d FAILED" % [_tests_passed, _tests_failed])
	print("=".repeat(60) + "\n")

	if auto_quit:
		get_tree().quit(0 if _tests_failed == 0 else 1)


func run_all_tests() -> void:
	# Tests de instanciación
	test_can_instantiate()
	test_initial_state()

	# Tests de parámetros de sampling
	test_temperature_parameter()
	test_top_p_parameter()
	test_top_k_parameter()
	test_max_tokens_parameter()
	test_repeat_penalty_parameter()
	test_min_p_parameter()
	test_seed_parameter()

	# Tests de timeout
	test_timeout_parameter()
	test_timeout_initial_state()

	# Tests de stop sequences
	test_stop_sequences()

	# Tests de modelo (sin modelo cargado)
	test_no_model_loaded_state()
	test_generate_without_model()

	# Tests con modelo (si está disponible)
	test_with_model_if_available()


# ==================== Helpers ====================

func _start_test(name: String) -> void:
	_current_test = name
	print("  [TEST] %s..." % name)


func _pass(msg: String = "") -> void:
	_tests_passed += 1
	if msg.is_empty():
		print("    ✓ PASSED")
	else:
		print("    ✓ PASSED: %s" % msg)


func _fail(msg: String) -> void:
	_tests_failed += 1
	print("    ✗ FAILED: %s" % msg)


func _assert_eq(actual, expected, msg: String = "") -> bool:
	if actual == expected:
		return true
	_fail("Expected %s but got %s. %s" % [expected, actual, msg])
	return false


func _assert_true(condition: bool, msg: String = "") -> bool:
	if condition:
		return true
	_fail("Expected true. %s" % msg)
	return false


func _assert_false(condition: bool, msg: String = "") -> bool:
	if not condition:
		return true
	_fail("Expected false. %s" % msg)
	return false


func _assert_approx(actual: float, expected: float, epsilon: float = 0.001, msg: String = "") -> bool:
	if abs(actual - expected) < epsilon:
		return true
	_fail("Expected ~%s but got %s. %s" % [expected, actual, msg])
	return false


# ==================== Tests de Instanciación ====================

func test_can_instantiate() -> void:
	_start_test("Puede instanciar LlamaInterface")
	var llama = LlamaInterface.new()
	if llama != null:
		_pass()
	else:
		_fail("No se pudo crear instancia")


func test_initial_state() -> void:
	_start_test("Estado inicial correcto")
	var llama = LlamaInterface.new()

	if not _assert_false(llama.is_model_loaded(), "Modelo no debería estar cargado"):
		return
	if not _assert_eq(llama.get_model_path(), "", "Path debería estar vacío"):
		return

	_pass()


# ==================== Tests de Parámetros ====================

func test_temperature_parameter() -> void:
	_start_test("Parámetro temperature")
	var llama = LlamaInterface.new()

	# Valor por defecto
	if not _assert_approx(llama.get_temperature(), 0.8, 0.01, "Default incorrecto"):
		return

	# Set y get
	llama.set_temperature(0.5)
	if not _assert_approx(llama.get_temperature(), 0.5, 0.01):
		return

	# Valor mínimo (0 = greedy)
	llama.set_temperature(0.0)
	if not _assert_approx(llama.get_temperature(), 0.0, 0.01, "Debería aceptar 0"):
		return

	# Valor negativo debe ser 0
	llama.set_temperature(-1.0)
	if not _assert_approx(llama.get_temperature(), 0.0, 0.01, "Negativo debe ser 0"):
		return

	_pass()


func test_top_p_parameter() -> void:
	_start_test("Parámetro top_p")
	var llama = LlamaInterface.new()

	if not _assert_approx(llama.get_top_p(), 0.95, 0.01, "Default incorrecto"):
		return

	llama.set_top_p(0.8)
	if not _assert_approx(llama.get_top_p(), 0.8, 0.01):
		return

	_pass()


func test_top_k_parameter() -> void:
	_start_test("Parámetro top_k")
	var llama = LlamaInterface.new()

	if not _assert_eq(llama.get_top_k(), 40, "Default incorrecto"):
		return

	llama.set_top_k(100)
	if not _assert_eq(llama.get_top_k(), 100):
		return

	# 0 desactiva top_k
	llama.set_top_k(0)
	if not _assert_eq(llama.get_top_k(), 0, "Debería aceptar 0"):
		return

	_pass()


func test_max_tokens_parameter() -> void:
	_start_test("Parámetro max_tokens")
	var llama = LlamaInterface.new()

	if not _assert_eq(llama.get_max_tokens(), 256, "Default incorrecto"):
		return

	llama.set_max_tokens(512)
	if not _assert_eq(llama.get_max_tokens(), 512):
		return

	# Mínimo debe ser 1
	llama.set_max_tokens(0)
	if not _assert_eq(llama.get_max_tokens(), 1, "Mínimo debe ser 1"):
		return

	_pass()


func test_repeat_penalty_parameter() -> void:
	_start_test("Parámetro repeat_penalty")
	var llama = LlamaInterface.new()

	if not _assert_approx(llama.get_repeat_penalty(), 1.1, 0.01, "Default incorrecto"):
		return

	llama.set_repeat_penalty(1.5)
	if not _assert_approx(llama.get_repeat_penalty(), 1.5, 0.01):
		return

	# Mínimo debe ser 1.0
	llama.set_repeat_penalty(0.5)
	if not _assert_approx(llama.get_repeat_penalty(), 1.0, 0.01, "Mínimo debe ser 1.0"):
		return

	_pass()


func test_min_p_parameter() -> void:
	_start_test("Parámetro min_p")
	var llama = LlamaInterface.new()

	if not _assert_approx(llama.get_min_p(), 0.05, 0.01, "Default incorrecto"):
		return

	llama.set_min_p(0.1)
	if not _assert_approx(llama.get_min_p(), 0.1, 0.01):
		return

	_pass()


func test_seed_parameter() -> void:
	_start_test("Parámetro seed")
	var llama = LlamaInterface.new()

	llama.set_seed(12345)
	if not _assert_eq(llama.get_seed(), 12345):
		return

	llama.set_seed(0)
	if not _assert_eq(llama.get_seed(), 0, "Debería aceptar 0"):
		return

	_pass()


# ==================== Tests de Timeout ====================

func test_timeout_parameter() -> void:
	_start_test("Parámetro timeout")
	var llama = LlamaInterface.new()

	# Por defecto es 0 (sin timeout)
	if not _assert_eq(llama.get_timeout(), 0, "Default debe ser 0"):
		return

	llama.set_timeout(5000)
	if not _assert_eq(llama.get_timeout(), 5000):
		return

	# Negativo debe ser 0
	llama.set_timeout(-100)
	if not _assert_eq(llama.get_timeout(), 0, "Negativo debe ser 0"):
		return

	_pass()


func test_timeout_initial_state() -> void:
	_start_test("Estado inicial de timeout")
	var llama = LlamaInterface.new()

	# No debería haber timeout antes de generar
	if not _assert_false(llama.has_generation_timed_out(), "No debe haber timeout al inicio"):
		return

	_pass()


# ==================== Tests de Stop Sequences ====================

func test_stop_sequences() -> void:
	_start_test("Stop sequences")
	var llama = LlamaInterface.new()

	# Inicialmente vacío
	var sequences = llama.get_stop_sequences()
	if not _assert_eq(sequences.size(), 0, "Debe estar vacío al inicio"):
		return

	# Agregar secuencias
	llama.set_stop_sequences(PackedStringArray(["[END]", "\n\n", "User:"]))
	sequences = llama.get_stop_sequences()
	if not _assert_eq(sequences.size(), 3, "Debe tener 3 secuencias"):
		return
	if not _assert_eq(sequences[0], "[END]"):
		return

	# Limpiar
	llama.clear_stop_sequences()
	sequences = llama.get_stop_sequences()
	if not _assert_eq(sequences.size(), 0, "Debe estar vacío después de limpiar"):
		return

	_pass()


# ==================== Tests de Modelo ====================

func test_no_model_loaded_state() -> void:
	_start_test("Estado sin modelo cargado")
	var llama = LlamaInterface.new()

	var info = llama.get_model_info()
	if not _assert_true(info.is_empty(), "Info debe estar vacío sin modelo"):
		return

	_pass()


func test_generate_without_model() -> void:
	_start_test("Generate sin modelo devuelve vacío")
	var llama = LlamaInterface.new()

	var result = llama.generate("Hello")
	if not _assert_eq(result, "", "Debe devolver string vacío"):
		return

	_pass()


func test_with_model_if_available() -> void:
	_start_test("Test con modelo (si está disponible)")

	# Buscar modelo en res://models/
	var models_dir = "res://models/"
	var dir = DirAccess.open(models_dir)

	if dir == null:
		print("    ⊘ SKIPPED: Directorio models/ no encontrado")
		return

	var model_path: String = ""
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".gguf"):
			model_path = models_dir + file_name
			break
		file_name = dir.get_next()
	dir.list_dir_end()

	if model_path.is_empty():
		print("    ⊘ SKIPPED: No hay modelos .gguf disponibles")
		return

	print("    Usando modelo: %s" % model_path)

	var llama = LlamaInterface.new()
	var err = llama.load_model(model_path, {"n_ctx": 512, "n_gpu_layers": 0})

	if err != OK:
		print("    ⊘ SKIPPED: Error cargando modelo (%d)" % err)
		return

	if not _assert_true(llama.is_model_loaded(), "Modelo debería estar cargado"):
		llama.unload_model()
		return

	# Test info del modelo
	var info = llama.get_model_info()
	if not _assert_false(info.is_empty(), "Info no debe estar vacío"):
		llama.unload_model()
		return

	# Test generación básica
	llama.set_max_tokens(10)
	llama.set_temperature(0.0)  # Greedy para reproducibilidad

	var result = llama.generate("The capital of France is")
	if not _assert_true(result.length() > 0, "Debería generar texto"):
		llama.unload_model()
		return

	print("    Generado: '%s'" % result.substr(0, 50))

	# Test timeout (con timeout muy corto)
	llama.set_timeout(1)  # 1ms - debería hacer timeout
	llama.set_max_tokens(1000)
	var result_timeout = llama.generate("Write a very long story about")

	# Puede o no hacer timeout dependiendo de la velocidad
	if llama.has_generation_timed_out():
		print("    Timeout funcionó correctamente")
	else:
		print("    Generación completó antes del timeout (OK)")

	llama.unload_model()

	if not _assert_false(llama.is_model_loaded(), "Modelo debería estar descargado"):
		return

	_pass("Todos los tests con modelo pasaron")
