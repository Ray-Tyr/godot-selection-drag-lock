@tool
extends EditorPlugin

const BUTTON_TEXT: String = "Lock Drag"
const ACTION_NAME: String = "Lock Drag Node2D"
const SHORTCUT_PATH: String = "selection_drag_lock/toggle_lock_drag"
const MIN_MOVE_DISTANCE_SQUARED: float = 0.0001

var _toggle_button: Button
var _enabled: bool = true
var _dragging: bool = false
var _drag_nodes: Array[Node2D] = []
var _start_positions: Dictionary = {}
var _last_mouse_world: Vector2 = Vector2.ZERO
var _has_moved: bool = false


func _enter_tree() -> void:
	_toggle_button = Button.new()
	_toggle_button.text = BUTTON_TEXT
	_toggle_button.toggle_mode = true
	_toggle_button.button_pressed = _enabled
	_toggle_button.tooltip_text = "Drag the selected Node2D nodes without selecting another viewport item."
	_toggle_button.shortcut = _get_toggle_shortcut()
	_toggle_button.toggled.connect(_on_toggle_toggled)

	var editor_theme: Theme = EditorInterface.get_editor_theme()
	if editor_theme.has_icon("ToolMove", "EditorIcons"):
		_toggle_button.icon = editor_theme.get_icon("ToolMove", "EditorIcons")

	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, _toggle_button)


func _get_toggle_shortcut() -> Shortcut:
	var editor_settings: EditorSettings = EditorInterface.get_editor_settings()
	if not editor_settings.has_shortcut(SHORTCUT_PATH):
		editor_settings.add_shortcut(SHORTCUT_PATH, _create_default_toggle_shortcut())

	return editor_settings.get_shortcut(SHORTCUT_PATH)


func _create_default_toggle_shortcut() -> Shortcut:
	var shortcut: Shortcut = Shortcut.new()
	var key_event: InputEventKey = InputEventKey.new()
	key_event.keycode = KEY_D
	key_event.alt_pressed = true
	key_event.shift_pressed = true
	shortcut.events.append(key_event)
	return shortcut


func _exit_tree() -> void:
	_finish_drag()

	if _toggle_button != null:
		remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, _toggle_button)
		_toggle_button.queue_free()
		_toggle_button = null


func _handles(object: Object) -> bool:
	return object is Node2D


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if not _enabled:
		return false

	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if mouse_button_event.button_index != MOUSE_BUTTON_LEFT:
			return false

		if mouse_button_event.pressed:
			return _begin_drag(mouse_button_event.position)

		if _dragging:
			_finish_drag()
			return true

	if event is InputEventMouseMotion and _dragging:
		var mouse_motion_event: InputEventMouseMotion = event
		if (mouse_motion_event.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			_finish_drag()
			return true

		_apply_drag(mouse_motion_event.position)
		return true

	return _dragging


func _on_toggle_toggled(enabled: bool) -> void:
	_enabled = enabled
	if not _enabled:
		_finish_drag()


func _begin_drag(viewport_position: Vector2) -> bool:
	_drag_nodes = _get_selected_node2d_roots()
	if _drag_nodes.size() == 0:
		return false

	_start_positions.clear()
	for node: Node2D in _drag_nodes:
		_start_positions[node] = node.global_position

	_last_mouse_world = _viewport_to_world(viewport_position)
	_dragging = true
	_has_moved = false
	return true


func _apply_drag(viewport_position: Vector2) -> void:
	var mouse_world: Vector2 = _viewport_to_world(viewport_position)
	var delta: Vector2 = mouse_world - _last_mouse_world
	if delta.length_squared() <= MIN_MOVE_DISTANCE_SQUARED:
		return

	for node: Node2D in _drag_nodes:
		if is_instance_valid(node):
			node.global_position += delta

	_last_mouse_world = mouse_world
	_has_moved = true


func _finish_drag() -> void:
	if not _dragging:
		return

	if _has_moved:
		_commit_drag_action()

	_dragging = false
	_drag_nodes.clear()
	_start_positions.clear()
	_last_mouse_world = Vector2.ZERO
	_has_moved = false


func _commit_drag_action() -> void:
	var moved_nodes: Array[Node2D] = []
	var undo_positions: Array[Vector2] = []
	var do_positions: Array[Vector2] = []

	for node: Node2D in _drag_nodes:
		if not is_instance_valid(node):
			continue
		if not _start_positions.has(node):
			continue

		var undo_position: Vector2 = _start_positions[node]
		var do_position: Vector2 = node.global_position
		if undo_position.distance_squared_to(do_position) <= MIN_MOVE_DISTANCE_SQUARED:
			continue

		moved_nodes.append(node)
		undo_positions.append(undo_position)
		do_positions.append(do_position)

	if moved_nodes.size() == 0:
		return

	var undo_redo: EditorUndoRedoManager = get_undo_redo()
	undo_redo.create_action(ACTION_NAME)
	for index: int in moved_nodes.size():
		var moved_node: Node2D = moved_nodes[index]
		undo_redo.add_do_property(moved_node, "global_position", do_positions[index])
		undo_redo.add_undo_property(moved_node, "global_position", undo_positions[index])
	undo_redo.commit_action()


func _get_selected_node2d_roots() -> Array[Node2D]:
	var selected_nodes: Array[Node] = EditorInterface.get_selection().get_top_selected_nodes()
	var node2d_nodes: Array[Node2D] = []
	for node: Node in selected_nodes:
		if node is Node2D:
			node2d_nodes.append(node)
	return node2d_nodes


func _viewport_to_world(viewport_position: Vector2) -> Vector2:
	var viewport: SubViewport = EditorInterface.get_editor_viewport_2d()
	var canvas_transform: Transform2D = viewport.global_canvas_transform
	return canvas_transform.affine_inverse() * viewport_position
