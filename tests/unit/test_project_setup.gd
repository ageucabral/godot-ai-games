extends "res://tests/test_case.gd"
## Confere que a configuração base do projeto continua correta.


func test_renderer_is_compatibility() -> void:
	assert_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method"), "gl_compatibility", "renderizador")


func test_main_scene_is_set() -> void:
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene")
	assert_true(ResourceLoader.exists(main_scene), "cena principal existe: " + main_scene)


func test_main_scene_instantiates() -> void:
	var packed: PackedScene = load(ProjectSettings.get_setting("application/run/main_scene"))
	assert_not_null(packed, "cena principal carrega")
	var scene := packed.instantiate()
	add_child(scene)
	await get_tree().process_frame
	var label: Label = scene.get_node("CanvasLayer/Label")
	assert_true(label.text.begins_with("Projeto pronto!"), "texto de boas-vindas")
	scene.queue_free()


func test_welcome_text() -> void:
	var main_script := load("res://scripts/main.gd")
	assert_eq(main_script.build_welcome_text({"major": 4, "minor": 7, "patch": 2}), "Projeto pronto! Godot 4.7.2")
