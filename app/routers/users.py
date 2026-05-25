from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session 
import bcrypt
import jwt 
from jwt.exceptions import InvalidTokenError
from datetime import datetime, timedelta, timezone 
from app.db import UserDB, get_db
from app.schemas import CreateUser
from dotenv import load_dotenv
import os

load_dotenv()
router = APIRouter(prefix="/api/v1/users", tags=["Authentification"])

@router.post("/register")
def register_user(user: CreateUser, db: Session = Depends(get_db)):
    db_user = db.query(UserDB).filter(UserDB.username == user.username).first()
    if db_user: 
        raise HTTPException(status_code=400, detail="Username already used")
    
    password_bytes = user.password.encode('utf-8')
    salt = bcrypt.gensalt()
    
    hashed_password = bcrypt.hashpw(password_bytes, salt).decode('utf-8')
    
    new_user = UserDB(username=user.username, password=hashed_password)

    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return {
        "status": "success",
        "user_id": new_user.id
    }

def create_access_token(data: dict):
    to_encode = data.copy()
    
    expire_minutes = int(os.getenv("ACCESS_TOKEN_EXPIRE_MIN"))
    expire = datetime.now(timezone.utc) + timedelta(minutes=expire_minutes)
    to_encode.update({"exp": expire})

    encoded_jwt = jwt.encode(
        to_encode, 
        os.getenv("SECRET_KEY"), 
        algorithm=os.getenv("ALGORITHM", "HS256")
    )
    return encoded_jwt

@router.post("/login")
def login_user(user: CreateUser, db: Session = Depends(get_db)):
    db_user = db.query(UserDB).filter(UserDB.username == user.username).first()

    if not db_user:
        raise HTTPException(status_code=400, detail="Wrong Username or password")
    
    user_pass_bytes = user.password.encode('utf-8')
    db_pass_bytes = db_user.password.encode('utf-8')
    
    if not bcrypt.checkpw(user_pass_bytes, db_pass_bytes):
        raise HTTPException(status_code=400, detail="Wrong Username or password")

    access_token = create_access_token(data={"sub": str(db_user.id)})

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": db_user.id,
        "username": db_user.username
    }


oauth2_scheme = OAuth2PasswordBearer(tokenUrl = "/api/v1/users/login")


def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=401,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(
            token,
            os.getenv("SECRET_KEY"),
            algorithms=[os.getenv("ALGORITHM")],
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
        return int(user_id)
    except InvalidTokenError:
        raise credentials_exception