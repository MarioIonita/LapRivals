from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session 
from app.db import SessionLocal, RaceResultsDB, TelemetryDataDB, UserDB
from app.schemas import RaceUpload
from app.routers.users import get_current_user 
from sqlalchemy.exc import SQLAlchemyError

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
    print(f"-> [DB UPLOAD ATTEMPT]: User: {current_user_id}, Track: {race_data.track_id}, Time: {race_data.final_time}")
    
    if race_data.final_time < 12.0:
        raise HTTPException(status_code=406, detail="Invalid Time. Pls dont cheat.")

    try:
        mode_to_save = race_data.game_mode if race_data.game_mode else "SINGLE_PLAYER"
        
        new_result = RaceResultsDB( 
            user_id=current_user_id,
            track_id=race_data.track_id, 
            final_time=race_data.final_time,
            game_mode=mode_to_save
        )
        db.add(new_result)
        db.commit()
        db.refresh(new_result)

        telemetry_dicts = [frame.model_dump() for frame in race_data.telemetry]
        new_telemetry = TelemetryDataDB(race_result_id=new_result.id, ghost_data_json=telemetry_dicts)
        db.add(new_telemetry)
        db.commit()
        
        print(f"   [DB SUCCESS]: Successful insertion! New race ID: {new_result.id}")
        return {"status": "success", "message": "Saved Data", "id": new_result.id}

    except SQLAlchemyError as e:
        db.rollback() 
        print(f"!!! [DB CRITICAL ERROR]: Postgres denied the save! Reason: {e}")
        
       
        try:
            print("   [DB RETRY]: Forced insertion with game_mode='SINGLE_PLAYER'...")
            new_result = RaceResultsDB( 
                user_id=current_user_id,
                track_id=race_data.track_id, 
                final_time=race_data.final_time,
                game_mode="SINGLE_PLAYER" # Seed fallback 
            )
            db.add(new_result)
            db.commit()
            db.refresh(new_result)

            telemetry_dicts = [frame.model_dump() for frame in race_data.telemetry]
            new_telemetry = TelemetryDataDB(race_result_id=new_result.id, ghost_data_json=telemetry_dicts)
            db.add(new_telemetry)
            db.commit()
            
            print(f"   [DB RETRY SUCCESS]: Saved with fallback!")
            return {"status": "success", "message": "Saved data via fallback", "id": new_result.id}
            
        except SQLAlchemyError as e_retry:
            db.rollback()
            print(f"!!! [DB FATAL]: Fallback error: {e_retry}")
            raise HTTPException(status_code=500, detail=f"Database execution failed: {str(e_retry)}")
@router.get("/get_ghost/{track_id}")
def get_ghost(track_id: int, db: Session = Depends(get_db), current_user_id: int = Depends(get_current_user)):
    print(f"-> Personal Ghost requested for user {current_user_id} on track {track_id}...")
    
    
    best_race = db.query(RaceResultsDB).filter(
        RaceResultsDB.track_id == track_id,
        RaceResultsDB.user_id == current_user_id
    ).order_by(RaceResultsDB.final_time.asc()).first()
    
    if not best_race:
        raise HTTPException(status_code=404, detail="You haven't recorded any laps on this track yet.")
        
    telemetry = db.query(TelemetryDataDB).filter(TelemetryDataDB.race_result_id == best_race.id).first()
    
    if not telemetry:
        raise HTTPException(status_code=404, detail="Telemetry data missing for your best race.")
        
    return {
        "status": "success",
        "best_time": best_race.final_time,
        "telemetry": telemetry.ghost_data_json
    }

@router.get("/get_swarm_data/{track_id}")
def get_swarm_data(track_id: int, db: Session = Depends(get_db)):
    print(f"-> Swarm requested for track {track_id}...")
    
    ai_users = db.query(UserDB).filter(UserDB.username.in_(["AI_Easy", "AI_Medium"])).all()
    ai_ids = [user.id for user in ai_users]
    
    if not ai_ids:
        raise HTTPException(status_code=404, detail="AI drivers not initialized in DB.")
        
    bot_races = db.query(RaceResultsDB).filter(
        RaceResultsDB.track_id == track_id,
        RaceResultsDB.user_id.in_(ai_ids)
    ).all()
    
    swarm_payload = []
    for race_res in bot_races:
        telemetry = db.query(TelemetryDataDB).filter(TelemetryDataDB.race_result_id == race_res.id).first()
        if telemetry:
            bot_name = next((u.username for u in ai_users if u.id == race_res.user_id), "AI_Bot")
            swarm_payload.append({
                "bot_name": bot_name,
                "telemetry": telemetry.ghost_data_json
            })
            
    if not swarm_payload:
        raise HTTPException(status_code=404, detail="No bot telemetry data found.")
        
    return {"status": "success", "swarm": swarm_payload}

# Bot endpoint (just for inserting telemetry data)
@router.post("/utils/seed_bots")
def seed_bots(db: Session = Depends(get_db)):
    original_telemetry = db.query(TelemetryDataDB).filter(TelemetryDataDB.race_result_id == 1).first()
    if not original_telemetry:
        return {"message": "Please drive once."}
        
    ai_users = db.query(UserDB).filter(UserDB.username.in_(["AI_Easy", "AI_Medium"])).all()
    
    for ai in ai_users:
        already_has_race = db.query(RaceResultsDB).filter(RaceResultsDB.user_id == ai.id).first()
        if not already_has_race:
            new_race = RaceResultsDB(user_id=ai.id, track_id=101, final_time=20.0, game_mode="SINGLE_PLAYER")
            db.add(new_race)
            db.commit()
            db.refresh(new_race)
            
            new_tel = TelemetryDataDB(race_result_id=new_race.id, ghost_data_json=original_telemetry.ghost_data_json)
            db.add(new_tel)
            db.commit()
            
    return {"status": "success", "message": "Bots have now valid telemetry."}