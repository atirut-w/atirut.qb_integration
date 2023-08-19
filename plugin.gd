@tool
extends EditorPlugin


const SETTINGS = {
	"application/quixel_bridge/socket_port": 24981, # Default export port
	"application/quixel_bridge/tcp_wait_time_ms": 100,
	"application/quixel_bridge/max_tcp_wait_loops": 10,
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


func _start_server() -> void:
	print("Setting up socket server...")
	_server = TCPServer.new()
	_server.listen(_get_settings("socket_port"), "127.0.0.1") # Only allow local connections


func _stop_server() -> void:
	print("Stopping socket server...")
	_server.stop()


func _process(delta: float) -> void:
	if _server.is_connection_available():
		print("Received connection from Quixel Bridge... probably.")
		_stream_peer = _server.take_connection()

		var available := 0
		var timeout := _get_settings("max_tcp_wait_loops")
		while timeout > 0:
			if _stream_peer.get_available_bytes() > available:
				available = _stream_peer.get_available_bytes()
				timeout = 10
			else:
				timeout -= 1
				OS.delay_msec(_get_settings("tcp_wait_time_ms"))
		
		print("Done waiting for data.")
		var text := _stream_peer.get_utf8_string(available)

		print(text)


func _get_settings(name: String) -> Variant:
	return ProjectSettings["application/quixel_bridge/" + name]

