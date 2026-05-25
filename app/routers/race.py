from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session 
from app.db import SessionLocal, RaceResultsDB, TelemetryDataDB, UserDB
from app.schemas import RaceUpload
from app.routers.users import get_current_user 

router = APIRouter(prefix="/api/v1", tags=["Race & Telemetry"])

def get_db():
    db = SessionLocal()
    try: 
        yield db 
    finally:
        db.close()

@router.post("/upload_race")
def process_race_data(
    race_data: RaceUpload, 
    db: Session = Depends(get_db), 
    current_user_id: int = Depends(get_current_user) 
):
    print(f"Upload... User REAL: {current_user_id}, Traseu: {race_data.track_id}, Timp: {race_data.final_time}")
    
    # Anti-cheat
    if race_data.final_time < 12.0:
        raise HTTPException(status_code=406, detail="Timp invalid. Posibil cheat.")

    new_result = RaceResultsDB( 
        user_id=current_user_id,
        track_id=race_data.track_id, 
        final_time=race_data.final_time,
        game_mode=race_data.game_mode
    )
    db.add(new_result)
    db.commit()
    db.refresh(new_result)

    telemetry_dicts = [frame.model_dump() for frame in race_data.telemetry]
    new_telemetry = TelemetryDataDB(race_result_id=new_result.id, ghost_data_json=telemetry_dicts)
    db.add(new_telemetry)
    db.commit()
    
    return {"status": "success", "message": "Date salvate", "id": new_result.id}

@router.get("/get_ghost/{track_id}")
def get_ghost_data(
    track_id: int, 
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user) # <- Securitatea ramane activa
):
    print(f"-> Ghost Car (Time Trial) for track {track_id}, User ID: {current_user_id}...")
    
    # SQL: Cautam cea mai buna cursa a TA, strict in modul TIME_TRIAL
    best_race = db.query(RaceResultsDB).filter(
        RaceResultsDB.track_id == track_id,
        RaceResultsDB.user_id == current_user_id,
        RaceResultsDB.game_mode == "TIME_TRIAL"
    ).order_by(RaceResultsDB.final_time.asc()).first()
    
    if not best_race:
        raise HTTPException(status_code=404, detail="Nu ai niciun timp pe aceasta pista.")
        
    telemetry = db.query(TelemetryDataDB).filter(TelemetryDataDB.race_result_id == best_race.id).first()
    
    if not telemetry:
        raise HTTPException(status_code=404, detail="Telemetrie lipsa.")
    
    return {
        "status": "success",
        "pilot_id": best_race.user_id,
        "best_time": best_race.final_time,
        "telemetry": telemetry.ghost_data_json
    }

@router.get("/get_swarm_data/{track_id}")
def get_swarm_data(
    track_id: int, 
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user)
):
    opponents = db.query(RaceResultsDB).filter(
        RaceResultsDB.track_id == track_id,
        RaceResultsDB.user_id != current_user_id,
        RaceResultsDB.game_mode == "TIME_TRIAL" 
    ).order_by(RaceResultsDB.final_time.asc()).limit(3).all()
    
    if not opponents:
        raise HTTPException(status_code=404, detail="Nu exista suficienti oponenti in baza de date.")

    swarm_payload = []
    for opp in opponents:
        tel = db.query(TelemetryDataDB).filter(TelemetryDataDB.race_result_id == opp.id).first()
        if tel:
            swarm_payload.append({
                "opponent_id": opp.user_id,
                "final_time": opp.final_time,
                "telemetry": tel.ghost_data_json
            })
            
    return {"swarm": swarm_payload}