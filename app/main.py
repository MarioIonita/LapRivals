from fastapi import FastAPI 
from app.routers import race,users

app = FastAPI(title= "LapRivals API")

app.include_router(race.router)
app.include_router(users.router)