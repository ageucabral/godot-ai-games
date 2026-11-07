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
	assert_true(scene.get_node("Hub").visible, "abre no hub Na Lata")
	assert_false(scene.get_node("Game").visible)
	scene.queue_free()


func test_portrait_phone_layout() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 720, "largura")
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 1280, "altura (celular em pé)")
