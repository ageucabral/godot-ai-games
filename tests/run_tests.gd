extends SceneTree
## Executor de testes sem dependências externas.
## Uso: tools/run_tests.sh   (ou: godot --headless --script res://tests/run_tests.gd)
## Opcional: tools/run_tests.sh nome_parcial  -> roda só arquivos cujo nome contém o texto.
##
## Etapas:
##  1. Verifica se TODOS os scripts .gd e cenas .tscn do projeto carregam sem erro.
##  2. Roda cada função test_*() de cada arquivo tests/unit/test_*.gd.
## Sai com código 0 se tudo passou e 1 se algo falhou.

const TEST_DIR := "res://tests/unit"
const CHECK_DIRS := ["res://scenes", "res://scripts", "res://characters"]

var _passed := 0
var _failed := 0
var _failure_lines: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var filter := ""
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		filter = args[0]

	print("== 1/2 Verificando se scripts e cenas carregam ==")
	for dir in CHECK_DIRS:
		for path in _find_files(dir, [".gd", ".tscn"]):
			var res := load(path)
			if res == null or (res is Script and not res.can_instantiate()):
				_record_fail("[carregar] %s" % path, "não foi possível carregar (erro de sintaxe?)")
			else:
				_passed += 1

	print("== 2/2 Rodando testes ==")
	for path in _find_files(TEST_DIR, [".gd"]):
		if not path.get_file().begins_with("test_"):
			continue
		if filter != "" and not path.contains(filter):
			continue
		await _run_file(path)

	print("")
	print("Resultado: %d passaram, %d falharam" % [_passed, _failed])
	for line in _failure_lines:
		print("  FALHOU: " + line)
	quit(1 if _failed > 0 else 0)


func _run_file(path: String) -> void:
	var script: Script = load(path)
	if script == null or not script.can_instantiate():
		_record_fail(path, "arquivo de teste não carregou")
		return
	var methods: Array[String] = []
	for m in script.get_script_method_list():
		var name: String = m["name"]
		if name.begins_with("test_") and not methods.has(name):
			methods.append(name)
	methods.sort()
	print("-- %s (%d testes)" % [path.get_file(), methods.size()])
	for method in methods:
		var instance: Node = script.new()
		root.add_child(instance)
		await instance.before_each()
		await instance.call(method)
		await instance.after_each()
		var failures: Array[String] = instance._failures
		if failures.is_empty():
			_passed += 1
			print("   ok   %s" % method)
		else:
			_record_fail("%s :: %s" % [path.get_file(), method], "; ".join(failures))
		instance.queue_free()
		await process_frame


func _record_fail(name: String, why: String) -> void:
	_failed += 1
	_failure_lines.append("%s -> %s" % [name, why])
	print("   ERRO %s -> %s" % [name, why])


func _find_files(dir_path: String, extensions: Array) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	for sub in dir.get_directories():
		found.append_array(_find_files(dir_path.path_join(sub), extensions))
	for file in dir.get_files():
		for ext in extensions:
			if file.ends_with(ext):
				found.append(dir_path.path_join(file))
	found.sort()
	return found
