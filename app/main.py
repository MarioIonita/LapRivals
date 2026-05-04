from fastapi import FastAPI 
from app.routers import race

app = FastAPI(title= "LapRivals API")

app.include_router(race.router)