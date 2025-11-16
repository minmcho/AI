from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import timedelta
from pydantic import BaseModel, EmailStr
from typing import Optional, List

from app.db.database import get_db
from app.services.auth_service import auth_service
from app.config.settings import get_settings

settings = get_settings()
router = APIRouter(prefix="/auth", tags=["Authentication"])

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")


# Pydantic models
class UserRegistration(BaseModel):
    email: EmailStr
    username: str
    password: str
    full_name: Optional[str] = None
    age: Optional[int] = None
    weight_kg: Optional[float] = None
    height_cm: Optional[int] = None
    sex: Optional[str] = None  # "male", "female", "other"
    allergies: Optional[List[str]] = []
    dietary_restrictions: Optional[List[str]] = []
    health_goals: Optional[List[str]] = []
    activity_level: Optional[str] = "moderate"
    medical_conditions: Optional[List[str]] = []


class UserLogin(BaseModel):
    email: str
    password: str


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    id: int
    email: str
    username: str
    full_name: Optional[str]
    age: Optional[int]
    weight_kg: Optional[float]
    height_cm: Optional[int]
    sex: Optional[str]
    target_calories: Optional[int]
    bmi: Optional[float]
    bmi_category: Optional[str]
    allergies: List[str]
    dietary_restrictions: List[str]
    health_goals: List[str]

    class Config:
        from_attributes = True


@router.post("/register", response_model=UserResponse)
async def register(
    user_data: UserRegistration,
    db: AsyncSession = Depends(get_db)
):
    """
    Register a new user with comprehensive health profile

    - **email**: Valid email address
    - **username**: Unique username
    - **password**: Strong password (min 8 characters)
    - **age**: User's age in years
    - **weight_kg**: Weight in kilograms
    - **height_cm**: Height in centimeters
    - **sex**: Biological sex (male/female/other) for calorie calculation
    - **allergies**: List of food allergies
    - **dietary_restrictions**: List of dietary preferences (vegan, keto, etc.)
    - **health_goals**: List of health objectives
    """
    try:
        # Validate password strength
        if len(user_data.password) < 8:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Password must be at least 8 characters long"
            )

        user = await auth_service.register_user(
            db=db,
            email=user_data.email,
            username=user_data.username,
            password=user_data.password,
            full_name=user_data.full_name,
            age=user_data.age,
            weight_kg=user_data.weight_kg,
            height_cm=user_data.height_cm,
            sex=user_data.sex,
            allergies=user_data.allergies,
            dietary_restrictions=user_data.dietary_restrictions,
            health_goals=user_data.health_goals,
        )

        # Calculate BMI
        bmi = None
        bmi_category = None
        if user.weight_kg and user.height_cm:
            bmi = auth_service.calculate_bmi(user.weight_kg, user.height_cm)
            bmi_category = auth_service.get_bmi_category(bmi)

        return UserResponse(
            id=user.id,
            email=user.email,
            username=user.username,
            full_name=user.full_name,
            age=user.age,
            weight_kg=user.weight_kg,
            height_cm=user.height_cm,
            sex=user.sex.value if user.sex else None,
            target_calories=user.target_calories,
            bmi=round(bmi, 1) if bmi else None,
            bmi_category=bmi_category,
            allergies=user.allergies,
            dietary_restrictions=user.dietary_restrictions,
            health_goals=user.health_goals,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.post("/login", response_model=Token)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db)
):
    """
    Login with email and password

    Returns JWT access token and refresh token
    """
    user = await auth_service.authenticate_user(
        db=db,
        email=form_data.username,  # OAuth2 uses username field
        password=form_data.password
    )

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is inactive"
        )

    # Create tokens
    access_token = auth_service.create_access_token(
        data={"sub": user.id, "email": user.email}
    )
    refresh_token = auth_service.create_refresh_token(
        data={"sub": user.id}
    )

    return Token(
        access_token=access_token,
        refresh_token=refresh_token
    )


@router.post("/refresh", response_model=Token)
async def refresh_token(
    refresh_token: str,
    db: AsyncSession = Depends(get_db)
):
    """
    Refresh access token using refresh token
    """
    payload = auth_service.decode_token(refresh_token)

    if not payload or payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token"
        )

    user_id = payload.get("sub")
    user = await db.get(User, user_id)

    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive"
        )

    # Create new tokens
    new_access_token = auth_service.create_access_token(
        data={"sub": user.id, "email": user.email}
    )
    new_refresh_token = auth_service.create_refresh_token(
        data={"sub": user.id}
    )

    return Token(
        access_token=new_access_token,
        refresh_token=new_refresh_token
    )


@router.get("/me", response_model=UserResponse)
async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Get current authenticated user profile
    """
    user = await auth_service.get_current_user(db=db, token=token)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Calculate BMI
    bmi = None
    bmi_category = None
    if user.weight_kg and user.height_cm:
        bmi = auth_service.calculate_bmi(user.weight_kg, user.height_cm)
        bmi_category = auth_service.get_bmi_category(bmi)

    return UserResponse(
        id=user.id,
        email=user.email,
        username=user.username,
        full_name=user.full_name,
        age=user.age,
        weight_kg=user.weight_kg,
        height_cm=user.height_cm,
        sex=user.sex.value if user.sex else None,
        target_calories=user.target_calories,
        bmi=round(bmi, 1) if bmi else None,
        bmi_category=bmi_category,
        allergies=user.allergies,
        dietary_restrictions=user.dietary_restrictions,
        health_goals=user.health_goals,
    )


@router.post("/logout")
async def logout(token: str = Depends(oauth2_scheme)):
    """
    Logout user (client should delete token)
    """
    # In a production system, you might want to:
    # - Add token to blacklist
    # - Revoke refresh tokens
    # - Clear session data
    return {"message": "Successfully logged out"}


@router.post("/change-password")
async def change_password(
    current_password: str,
    new_password: str,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Change user password
    """
    user = await auth_service.get_current_user(db=db, token=token)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )

    # Verify current password
    if not auth_service.verify_password(current_password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect current password"
        )

    # Validate new password
    if len(new_password) < 8:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="New password must be at least 8 characters long"
        )

    # Update password
    user.hashed_password = auth_service.get_password_hash(new_password)
    await db.commit()

    return {"message": "Password changed successfully"}
