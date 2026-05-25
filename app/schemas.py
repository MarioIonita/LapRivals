from pydantic import BaseModel,Field 
from typing import List 

class TelemetryFrame(BaseModel):
    t: float 
    px: float 
    py : float 
    pz : float 
    rx : float 
    ry: float 
    rz : float 
    rw : float 
class RaceUpload(BaseModel):
    track_id : int 
    final_time : float 
    game_mode : str 
    telemetry : List[TelemetryFrame]

class CreateUser(BaseModel):
    username: str = Field(min_length=3, max_length=50)
    password: str = Field(min_length=6, max_length=70)