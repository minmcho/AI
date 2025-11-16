from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
from typing import Optional, Dict
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.config.settings import get_settings
from app.models.user import User

settings = get_settings()

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class AuthService:
    """Authentication and authorization service"""

    @staticmethod
    def verify_password(plain_password: str, hashed_password: str) -> bool:
        """Verify a password against its hash"""
        return pwd_context.verify(plain_password, hashed_password)

    @staticmethod
    def get_password_hash(password: str) -> str:
        """Hash a password"""
        return pwd_context.hash(password)

    @staticmethod
    def create_access_token(data: Dict, expires_delta: Optional[timedelta] = None) -> str:
        """Create JWT access token"""
        to_encode = data.copy()

        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)

        to_encode.update({"exp": expire})
        encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

        return encoded_jwt

    @staticmethod
    def create_refresh_token(data: Dict) -> str:
        """Create JWT refresh token (valid for 7 days)"""
        to_encode = data.copy()
        expire = datetime.utcnow() + timedelta(days=7)
        to_encode.update({"exp": expire, "type": "refresh"})

        encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
        return encoded_jwt

    @staticmethod
    def decode_token(token: str) -> Optional[Dict]:
        """Decode and verify JWT token"""
        try:
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
            return payload
        except JWTError:
            return None

    @staticmethod
    async def authenticate_user(db: AsyncSession, email: str, password: str) -> Optional[User]:
        """Authenticate user with email and password"""
        result = await db.execute(
            select(User).where(User.email == email)
        )
        user = result.scalar_one_or_none()

        if not user:
            return None

        if not AuthService.verify_password(password, user.hashed_password):
            return None

        return user

    @staticmethod
    async def get_current_user(db: AsyncSession, token: str) -> Optional[User]:
        """Get current user from JWT token"""
        payload = AuthService.decode_token(token)

        if payload is None:
            return None

        user_id: int = payload.get("sub")
        if user_id is None:
            return None

        result = await db.execute(
            select(User).where(User.id == user_id)
        )
        user = result.scalar_one_or_none()

        return user

    @staticmethod
    async def register_user(
        db: AsyncSession,
        email: str,
        username: str,
        password: str,
        full_name: Optional[str] = None,
        age: Optional[int] = None,
        weight_kg: Optional[float] = None,
        height_cm: Optional[int] = None,
        sex: Optional[str] = None,
        allergies: Optional[list] = None,
        dietary_restrictions: Optional[list] = None,
        health_goals: Optional[list] = None,
    ) -> User:
        """Register a new user with health profile"""

        # Check if user already exists
        result = await db.execute(
            select(User).where((User.email == email) | (User.username == username))
        )
        existing_user = result.scalar_one_or_none()

        if existing_user:
            raise ValueError("User with this email or username already exists")

        # Calculate BMI if weight and height provided
        bmi = None
        if weight_kg and height_cm:
            height_m = height_cm / 100
            bmi = weight_kg / (height_m ** 2)

        # Calculate recommended daily calories using Harris-Benedict equation
        daily_calories = AuthService.calculate_daily_calories(
            age=age,
            weight_kg=weight_kg,
            height_cm=height_cm,
            sex=sex,
            activity_level="moderate"
        )

        # Create user
        user = User(
            email=email,
            username=username,
            hashed_password=AuthService.get_password_hash(password),
            full_name=full_name,
            age=age,
            weight_kg=weight_kg,
            height_cm=height_cm,
            sex=sex,
            allergies=allergies or [],
            dietary_restrictions=dietary_restrictions or [],
            health_goals=health_goals or [],
            target_calories=daily_calories,
            is_active=True,
        )

        db.add(user)
        await db.commit()
        await db.refresh(user)

        return user

    @staticmethod
    def calculate_daily_calories(
        age: Optional[int],
        weight_kg: Optional[float],
        height_cm: Optional[int],
        sex: Optional[str],
        activity_level: str = "moderate"
    ) -> int:
        """Calculate recommended daily calories using Harris-Benedict equation"""

        if not all([age, weight_kg, height_cm, sex]):
            return 2000  # Default

        # Harris-Benedict BMR calculation
        if sex.lower() in ['male', 'm']:
            bmr = 88.362 + (13.397 * weight_kg) + (4.799 * height_cm) - (5.677 * age)
        else:  # female
            bmr = 447.593 + (9.247 * weight_kg) + (3.098 * height_cm) - (4.330 * age)

        # Activity multipliers
        activity_multipliers = {
            "sedentary": 1.2,
            "light": 1.375,
            "moderate": 1.55,
            "active": 1.725,
            "very_active": 1.9
        }

        multiplier = activity_multipliers.get(activity_level, 1.55)
        daily_calories = int(bmr * multiplier)

        return daily_calories

    @staticmethod
    def calculate_bmi(weight_kg: float, height_cm: int) -> float:
        """Calculate Body Mass Index"""
        height_m = height_cm / 100
        return weight_kg / (height_m ** 2)

    @staticmethod
    def get_bmi_category(bmi: float) -> str:
        """Get BMI category"""
        if bmi < 18.5:
            return "underweight"
        elif bmi < 25:
            return "normal"
        elif bmi < 30:
            return "overweight"
        else:
            return "obese"

    @staticmethod
    async def update_user_profile(
        db: AsyncSession,
        user: User,
        **kwargs
    ) -> User:
        """Update user profile"""

        for key, value in kwargs.items():
            if hasattr(user, key) and value is not None:
                setattr(user, key, value)

        # Recalculate calories if relevant fields changed
        if any(k in kwargs for k in ['age', 'weight_kg', 'height_cm', 'sex', 'activity_level']):
            user.target_calories = AuthService.calculate_daily_calories(
                age=user.age,
                weight_kg=user.weight_kg,
                height_cm=user.height_cm,
                sex=user.sex,
                activity_level=kwargs.get('activity_level', 'moderate')
            )

        await db.commit()
        await db.refresh(user)

        return user


# Singleton instance
auth_service = AuthService()
