@tool
extends EditorPlugin


const SETTINGS = {
	"application/quixel_bridge/socket_port": 24981, # Default export port
}

var _server: TCPServer
var _stream_peer: StreamPeer


func _enter_tree() -> void:
	for k in SETTINGS:
		if not ProjectSettings.has_setting(k):
			ProjectSettings.set_setting(k, SETTINGS[k])

		ProjectSettings.set_initial_value(k, SETTINGS[k])
		ProjectSettings.set_as_basic(k, true)

	_start_server()


func _exit_tree() -> void:
	_stop_server()


func _enable_plugin() -> void:
	push_warning(("BUG: Quixel Bridge settings will not appear until the project settings window is reopened."))


func _disable_plugin() -> void:
	for k in SETTINGS:
		ProjectSettings.set_setting(k, null)
	
	push_warning(("BUG: Quixel Bridge settings will not disappear until the project settings window is reopened."))


func _process(delta: float) -> void:
	if _server.is_connection_available():
		print_verbose("Received connection from Quixel Bridge.")
		_stream_peer = _server.take_connection()

		print_verbose("Waiting for data...")
		var received := ""
		var depth := 0

		while _stream_peer.get_available_bytes() == 0:
			pass
		
		var chunk := _stream_peer.get_utf8_string(_stream_peer.get_available_bytes())
		depth += _get_delta_depth(chunk)
		received += chunk

		while depth != 0:
			chunk = _stream_peer.get_utf8_string(_stream_peer.get_available_bytes())
			depth += _get_delta_depth(chunk)
			received += chunk
		
		print_verbose("Data received.")
		print(received)


func _get_delta_depth(chunk: String) -> int:
	var depth := 0
	for char in chunk:
		if char == "[":
			depth += 1
		elif char == "]":
			depth -= 1
	
	return depth


func _start_server() -> void:
	print_verbose("Starting socket server...")
	_server = TCPServer.new()
	_server.listen(_get_settings("socket_port"), "127.0.0.1") # Only allow local connections
	print_verbose("Socket server started on port %d." % _get_settings("socket_port"))


func _stop_server() -> void:
	print_verbose("Stopping socket server...")
	_server.stop()
	print_verbose("Socket server stopped.")


func _get_settings(name: String) -> Variant:
	return ProjectSettings["application/quixel_bridge/" + name]
