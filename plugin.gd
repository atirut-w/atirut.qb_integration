@tool
extends EditorPlugin


const SETTINGS = {
	"application/quixel_bridge/socket_port": 24981, # Default export port
}

var _port: int
var _server: TCPServer
var _stream_peer: StreamPeerTCP
var _socket_peer: WebSocketPeer


func _enter_tree() -> void:
	for k in SETTINGS:
		if not ProjectSettings.has_setting(k):
			ProjectSettings.set_setting(k, SETTINGS[k])

		ProjectSettings.set_initial_value(k, SETTINGS[k])
		ProjectSettings.set_as_basic(k, true)
	
	_port = ProjectSettings["application/quixel_bridge/socket_port"]
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
	_server.listen(_port, "127.0.0.1") # Only allow local connections
	_stream_peer = _server.take_connection()

	_socket_peer = WebSocketPeer.new()
	_socket_peer.accept_stream(_stream_peer)


func _stop_server() -> void:
	print("Stopping socket server...")
	_server.stop()
	_stream_peer = null
