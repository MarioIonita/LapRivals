from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session 
from app.db import SessionLocal,RaceResultsDB,TelemetryDataDB,UserDB
from app.schemas import RaceUpload

router = APIRouter(prefix = "/api/v1", tags = ["Race & Telemetry"])

def get_db():
    db = SessionLocal()
    try : 
        yield db 
    finally:
        db.close()

@router.post("/upload_race")
def process_race_data(race_data: RaceUpload, db: Session = Depends(get_db)):
    print(f"Date:.....User:{race_data.user_id}, Traseu : {race_data.track.id}, Timp : {race_data.final_time}")
    user = db.query(UserDB).filter(UserDB.id == race_data.user_id).first()

    if not user : 
        user = UserDB(id=race_data.user_id, 
                      username = f"Pilot_{race_data.user_id}")
        db.add(user)
        db.commit()
    new_result = RaceResultsDB( user_id=race_data.user_id, 
                               track_id=race_data.track_id, 
                               final_time=race_data.final_time)
    db.add(new_result)
    db.commit()
    db.refresh(new_result)


    telemetry_dicts = [frame.model_dump() for frame in race_data.telemetry]
    new_telemetry = TelemetryDataDB(race_result_id=new_result.id, ghost_data_json=telemetry_dicts)
    db.add(new_telemetry)
    db.commit()
    return {"status": "success", "message": "Date salvate", "id": new_result.id}

@router.get("/get_ghost/{track_id}")
def get_ghost_data(track_id: int, db: Session = Depends(get_db)):
    print(f"-> Ghost Car for track {track_id}...")
    best_race = db.query(RaceResultsDB).filter(RaceResultsDB.track_id == track_id).order_by(RaceResultsDB.final_time.asc()).first()
    if not best_race:
        raise HTTPException(status_code=404, detail="There were no races on this track yet.")
    telemetry = db.query(TelemetryDataDB).filter(TelemetryDataDB.race_result_id == best_race.id).first()
    if not telemetry:
        raise HTTPException(status_code=404, detail="Telemetrie lipsă.")
    
    return {
        "status": "success",
        "pilot_id": best_race.user_id,
        "best_time": best_race.final_time,
        "telemetry": telemetry.ghost_data_json
    }