from pydantic import BaseModel 
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
    user_id : int 
    track_id : int 
    final_time : float 
    telemetry : List[TelemetryFrame]