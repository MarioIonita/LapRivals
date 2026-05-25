from fastapi import FastAPI 
from app.routers import race, users
from app.db import SessionLocal, UserDB
from contextlib import asynccontextmanager 

@asynccontextmanager
async def lifespan(app: FastAPI):
    db = SessionLocal()
    try:
        bot_easy = db.query(UserDB).filter(UserDB.username == "AI_Easy").first()
        if not bot_easy:
            db.add(UserDB(username="AI_Easy", password="ai_static_account_no_login"))
            print("LOG [Lifespan]: Injectat driver AI_Easy.")
            
        bot_medium = db.query(UserDB).filter(UserDB.username == "AI_Medium").first()
        if not bot_medium:
            db.add(UserDB(username="AI_Medium", password="ai_static_account_no_login"))
            
        db.commit()
    except Exception as e:
        print(f"bot init error: {e}")
    finally:
        db.close()
        
    yield 
    

app = FastAPI(title="LapRivals API", lifespan=lifespan)

app.include_router(race.router)
app.include_router(users.router)