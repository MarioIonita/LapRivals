extends Node

var socket = WebSocketPeer.new()
var is_connected_to_server = false
var server_url = "ws://127.0.0.1:8000/ws/race/"

signal connected_to_server
signal connection_closed
signal data_received(payload)

func _process(_delta):
	socket.poll()
	var state = socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		if not is_connected_to_server:
			is_connected_to_server = true
			print("[WSClient] Connected to the Multiplayer server!")
			connected_to_server.emit()
		
		while socket.get_available_packet_count():
			var packet = socket.get_packet()
			var json_string = packet.get_string_from_utf8()
			var data = JSON.parse_string(json_string)
			
			if data:
				data_received.emit(data)
				
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
		
	elif state == WebSocketPeer.STATE_CLOSED:
		if is_connected_to_server:
			is_connected_to_server = false
			print("[WSClient] Connection ended. Reason: ", socket.get_close_code(), " - ", socket.get_close_reason())
			connection_closed.emit()

func connect_to_server(client_id: int):
	print("[WSClient] Connection init at", server_url + str(client_id))
	var error = socket.connect_to_url(server_url + str(client_id))
	if error != OK:
		print("[WSClient] Critical error: Couldn't connect to WebSocket. Code: ", error)

func disconnect_from_server():
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.close(1000, "User disconnected normaly")

func send_data(dict_data: Dictionary):
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var json_string = JSON.stringify(dict_data)
		socket.send_text(json_string)
