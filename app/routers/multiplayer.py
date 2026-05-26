from fastapi import APIRouter, WebSocket, WebSocketDisconnect
import json


router = APIRouter(prefix="/ws", tags=["Multiplayer"])

class ConnectionManager:
    def __init__(self):
        self.active_connections: dict[int, WebSocket] = {}

    async def connect(self, websocket: WebSocket, client_id: int):
        await websocket.accept()
        self.active_connections[client_id] = websocket
        print(f"[WebSocket] Player {client_id} has entered the track. Players online: {len(self.active_connections)}")

    def disconnect(self, client_id: int):
        if client_id in self.active_connections:
            del self.active_connections[client_id]
            print(f"[WebSocket] Player {client_id} has left.")

    async def broadcast(self, message: dict, sender_id: int):
        for cid, connection in self.active_connections.items():
            if cid != sender_id:
                await connection.send_json(message)

manager = ConnectionManager()

@router.websocket("/race/{client_id}")
async def multiplayer_endpoint(websocket: WebSocket, client_id: int):
    await manager.connect(websocket, client_id)
    try:
        while True:
            data = await websocket.receive_text()
            payload = json.loads(data)
            
            payload["client_id"] = client_id
            
            await manager.broadcast(payload, client_id)
            
    except WebSocketDisconnect:
        manager.disconnect(client_id)
        disconnect_msg = {"type": "disconnect", "client_id": client_id}
        await manager.broadcast(disconnect_msg, client_id)