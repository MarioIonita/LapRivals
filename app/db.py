import os 
from dotenv import load_dotenv
import datetime 
from sqlalchemy import * 
from sqlalchemy.orm import declarative_base, sessionmaker


load_dotenv()

db_user = os.getenv("DB_USER")
db_password = os.getenv("DB_PASSWORD")
db_host = os.getenv("DB_HOST")
db_port = os.getenv("DB_PORT")
db_name = os.getenv("DB_NAME")

db_url = f"postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
engine = create_engine(db_url)
SessionLocal = sessionmaker(autoflush=False,autocommit = False, bind = engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db 
    finally: 
        db.close()

class UserDB(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index = True)
    username = Column(String, unique=True, index = True)
    password = Column(String)

class RaceResultsDB(Base):
    __tablename__ = "race_results"
    id = Column(Integer, primary_key=True, index = True)
    user_id = Column(Integer, ForeignKey("users.id"))
    track_id = Column(Integer, index = True)
    final_time = Column(Float)
    date_achieved = Column(DateTime, default = datetime.datetime.now())
    game_mode = Column(String)

class TelemetryDataDB(Base):
    __tablename__ = "telemetry_data"
    id = Column(Integer, primary_key=True, index = True)
    race_result_id = Column(Integer, ForeignKey("race_results.id"))
    ghost_data_json = Column(JSON)

Base.metadata.create_all(bind = engine)