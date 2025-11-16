# NutriVision AI - Authentication & User Guide

Complete guide for user registration, authentication, and personalized nutrition features.

## Table of Contents

1. [User Registration](#user-registration)
2. [Login & Authentication](#login--authentication)
3. [User Profile Management](#user-profile-management)
4. [Personalized Nutrition Features](#personalized-nutrition-features)
5. [API Examples](#api-examples)
6. [Security Features](#security-features)

---

## User Registration

### Register New User

Create an account with comprehensive health profile.

**Endpoint:** `POST /auth/register`

**Required Fields:**
- `email`: Valid email address
- `username`: Unique username
- `password`: Minimum 8 characters

**Optional Health Profile Fields:**
- `age`: Age in years (required for personalized recommendations)
- `weight_kg`: Weight in kilograms (required for BMI and calorie calculation)
- `height_cm`: Height in centimeters (required for BMI and calorie calculation)
- `sex`: Biological sex - "male", "female", or "other" (affects calorie calculation)
- `allergies`: List of food allergies (e.g., ["peanuts", "shellfish", "dairy"])
- `dietary_restrictions`: List of dietary preferences (e.g., ["vegetarian", "gluten_free"])
- `health_goals`: Health objectives (e.g., ["weight_loss", "muscle_gain"])
- `activity_level`: "sedentary", "light", "moderate", "active", "very_active"
- `medical_conditions`: List of medical conditions
- `medications`: Current medications

### Example Registration Request

```bash
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john.doe@example.com",
    "username": "johndoe",
    "password": "SecurePass123!",
    "full_name": "John Doe",
    "age": 30,
    "weight_kg": 75.5,
    "height_cm": 175,
    "sex": "male",
    "allergies": ["peanuts", "shellfish"],
    "dietary_restrictions": ["vegetarian"],
    "health_goals": ["weight_loss", "improve_fitness"],
    "activity_level": "moderate"
  }'
```

### Response

```json
{
  "id": 1,
  "email": "john.doe@example.com",
  "username": "johndoe",
  "full_name": "John Doe",
  "age": 30,
  "weight_kg": 75.5,
  "height_cm": 175,
  "sex": "male",
  "target_calories": 2250,
  "bmi": 24.7,
  "bmi_category": "normal",
  "allergies": ["peanuts", "shellfish"],
  "dietary_restrictions": ["vegetarian"],
  "health_goals": ["weight_loss", "improve_fitness"]
}
```

**Automatic Calculations:**
- **BMI**: Automatically calculated from weight and height
- **Daily Calorie Target**: Calculated using Harris-Benedict equation based on:
  - Age, weight, height, sex
  - Activity level
  - Health goals

---

## Login & Authentication

### Login

**Endpoint:** `POST /auth/login`

**Form Data (OAuth2):**
- `username`: Email address
- `password`: Password

```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=john.doe@example.com&password=SecurePass123!"
```

### Response

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

**Token Details:**
- **Access Token**: Valid for 30 minutes (configurable)
- **Refresh Token**: Valid for 7 days
- Use access token in `Authorization: Bearer <token>` header for API requests

### Get Current User

**Endpoint:** `GET /auth/me`

**Headers:** `Authorization: Bearer <access_token>`

```bash
curl -X GET http://localhost:8000/auth/me \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### Refresh Token

**Endpoint:** `POST /auth/refresh`

Refresh your access token when it expires.

```bash
curl -X POST "http://localhost:8000/auth/refresh?refresh_token=<your_refresh_token>"
```

### Change Password

**Endpoint:** `POST /auth/change-password`

**Headers:** `Authorization: Bearer <access_token>`

**Parameters:**
- `current_password`: Current password
- `new_password`: New password (min 8 characters)

---

## User Profile Management

### Update Profile

**Endpoint:** `PUT /profile/update`

**Headers:** `Authorization: Bearer <access_token>`

Update any profile information. Calorie targets are automatically recalculated.

```bash
curl -X PUT http://localhost:8000/profile/update \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "weight_kg": 73.0,
    "health_goals": ["weight_loss", "heart_health"],
    "activity_level": "active",
    "cuisine_preferences": ["mediterranean", "asian"]
  }'
```

**Updatable Fields:**
- `full_name`, `age`, `weight_kg`, `height_cm`, `sex`
- `activity_level`
- `allergies`, `dietary_restrictions`, `health_goals`
- `cuisine_preferences`, `disliked_ingredients`
- `medical_conditions`, `medications`

### Get Health Summary

**Endpoint:** `GET /profile/health-summary`

**Headers:** `Authorization: Bearer <access_token>`

Get comprehensive overview of your health profile.

```bash
curl -X GET http://localhost:8000/profile/health-summary \
  -H "Authorization: Bearer <token>"
```

**Response:**
```json
{
  "user_id": 1,
  "health_metrics": {
    "age": 30,
    "weight_kg": 73.0,
    "height_cm": 175,
    "sex": "male",
    "bmi": 23.8,
    "bmi_category": "normal",
    "activity_level": "active"
  },
  "nutrition_targets": {
    "daily_calories": 2450,
    "protein_g": 214.4,
    "carbs_g": 183.8,
    "fat_g": 95.4
  },
  "dietary_profile": {
    "restrictions": ["vegetarian"],
    "allergies": ["peanuts", "shellfish"],
    "health_goals": ["weight_loss", "heart_health"],
    "cuisine_preferences": ["mediterranean", "asian"],
    "disliked_ingredients": []
  },
  "medical_info": {
    "conditions": [],
    "medications": []
  }
}
```

---

## Personalized Nutrition Features

### Get AI Nutrition Recommendations

**Endpoint:** `GET /profile/nutrition-recommendations`

**Headers:** `Authorization: Bearer <access_token>`

Get personalized nutrition advice from AI agents based on your complete profile.

```bash
curl -X GET http://localhost:8000/profile/nutrition-recommendations \
  -H "Authorization: Bearer <token>"
```

**What You Get:**
- Current nutrition assessment
- Specific recommendations for your health goals
- Foods to emphasize
- Foods to limit/avoid
- Supplement recommendations
- Lifestyle tips
- Timeline and expectations

**AI Agent Used:** Personalized Nutrition Advisor

**Example Response:**
```json
{
  "user_id": 1,
  "recommendations": "Based on your profile (30 years old, 73kg, 175cm, BMI 23.8)...",
  "bmi": 23.8,
  "bmi_category": "normal",
  "generated_by": "Personalized Nutrition Advisor"
}
```

### Generate Personalized Meal Plan

**Endpoint:** `POST /profile/generate-meal-plan?days=7`

**Headers:** `Authorization: Bearer <access_token>`

**Query Parameters:**
- `days`: Number of days (1-30, default: 7)

Generate a complete personalized meal plan using multi-agent AI system.

```bash
curl -X POST "http://localhost:8000/profile/generate-meal-plan?days=7" \
  -H "Authorization: Bearer <token>"
```

**AI Agents Used:**
1. **Macronutrient Calculator** - Calculates optimal protein/carbs/fat ratios
2. **Personalized Nutrition Advisor** - Creates the meal plan
3. **Allergy Safety Specialist** - Verifies meals are allergen-free

**What's Included:**
- Daily meals (breakfast, lunch, dinner, snacks)
- Specific food items and portions
- Calorie counts per meal
- Total daily macros
- Safety verification for allergies
- Variety and balance across days

**Example Response:**
```json
{
  "user_id": 1,
  "days": 7,
  "meal_plan": "DAY 1:\n\nBreakfast (7:00 AM):\n- Greek yogurt parfait...",
  "user_profile": {
    "age": 30,
    "weight_kg": 73.0,
    "height_cm": 175,
    "bmi": 23.8,
    "target_calories": 2450,
    "allergies": ["peanuts", "shellfish"],
    "dietary_restrictions": ["vegetarian"],
    "health_goals": ["weight_loss", "heart_health"]
  },
  "generated_by": "Smart Multi-Agent Nutrition System",
  "agents_used": [
    "Macronutrient Calculator",
    "Personalized Nutrition Advisor",
    "Allergy Safety Specialist"
  ]
}
```

---

## API Examples

### Python Example

```python
import requests

# Base URL
BASE_URL = "http://localhost:8000"

# 1. Register
register_data = {
    "email": "jane@example.com",
    "username": "jane",
    "password": "SecurePass123!",
    "age": 28,
    "weight_kg": 65.0,
    "height_cm": 165,
    "sex": "female",
    "allergies": ["dairy"],
    "health_goals": ["weight_loss"],
    "activity_level": "moderate"
}

response = requests.post(f"{BASE_URL}/auth/register", json=register_data)
user = response.json()
print(f"Registered user: {user['username']}, BMI: {user['bmi']}")

# 2. Login
login_data = {
    "username": "jane@example.com",
    "password": "SecurePass123!"
}

response = requests.post(f"{BASE_URL}/auth/login", data=login_data)
tokens = response.json()
access_token = tokens["access_token"]

# 3. Get personalized recommendations
headers = {"Authorization": f"Bearer {access_token}"}
response = requests.get(f"{BASE_URL}/profile/nutrition-recommendations", headers=headers)
recommendations = response.json()
print(f"Recommendations: {recommendations['recommendations'][:200]}...")

# 4. Generate meal plan
response = requests.post(f"{BASE_URL}/profile/generate-meal-plan?days=7", headers=headers)
meal_plan = response.json()
print(f"Generated {meal_plan['days']}-day plan using {len(meal_plan['agents_used'])} AI agents")

# 5. Update profile
update_data = {"weight_kg": 63.5}
response = requests.put(f"{BASE_URL}/profile/update", json=update_data, headers=headers)
updated_user = response.json()
print(f"Updated weight: {updated_user['weight_kg']} kg, new BMI: {updated_user['bmi']}")
```

### JavaScript Example

```javascript
const BASE_URL = "http://localhost:8000";

// Register
async function register() {
  const response = await fetch(`${BASE_URL}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: "john@example.com",
      username: "john",
      password: "SecurePass123!",
      age: 35,
      weight_kg: 80,
      height_cm: 180,
      sex: "male",
      health_goals: ["muscle_gain"],
      activity_level: "active"
    })
  });
  return response.json();
}

// Login
async function login(email, password) {
  const formData = new URLSearchParams();
  formData.append('username', email);
  formData.append('password', password);

  const response = await fetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    body: formData
  });
  return response.json();
}

// Get meal plan
async function getMealPlan(accessToken, days = 7) {
  const response = await fetch(`${BASE_URL}/profile/generate-meal-plan?days=${days}`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`
    }
  });
  return response.json();
}

// Usage
(async () => {
  const user = await register();
  console.log("Registered:", user);

  const tokens = await login(user.email, "SecurePass123!");
  const mealPlan = await getMealPlan(tokens.access_token, 7);
  console.log("Meal plan:", mealPlan);
})();
```

---

## Security Features

### Password Security
- **Minimum 8 characters** required
- **Bcrypt hashing** for password storage
- Never stored in plain text

### Token Security
- **JWT tokens** with expiration
- **Access tokens**: 30 minutes (configurable)
- **Refresh tokens**: 7 days
- Tokens signed with secret key (HS256 algorithm)

### API Security
- **CORS protection** - configurable origins
- **OAuth2 password flow** standard
- **Bearer token authentication** for protected endpoints
- **SQL injection protection** via SQLAlchemy ORM

### Data Privacy
- User data encrypted at rest (database level)
- Secure password reset (TODO)
- Email verification (TODO)
- Two-factor authentication (TODO)

---

## Health Goals Reference

Available health goals:
- `weight_loss` - Reduce body weight
- `weight_gain` - Increase body weight
- `muscle_gain` - Build muscle mass
- `maintain_weight` - Maintain current weight
- `improve_fitness` - Enhance overall fitness
- `manage_diabetes` - Blood sugar management
- `lower_cholesterol` - Reduce cholesterol levels
- `heart_health` - Cardiovascular health
- `digestive_health` - Gut health improvement
- `general_wellness` - Overall well-being

## Dietary Restrictions Reference

Available restrictions:
- `vegetarian` - No meat
- `vegan` - No animal products
- `gluten_free` - No gluten
- `dairy_free` - No dairy
- `keto` - Ketogenic diet
- `paleo` - Paleolithic diet
- `halal` - Islamic dietary laws
- `kosher` - Jewish dietary laws
- `low_carb` - Low carbohydrate
- `low_fat` - Low fat

## Activity Levels Reference

- `sedentary` - Little to no exercise
- `light` - Exercise 1-3 days/week
- `moderate` - Exercise 3-5 days/week
- `active` - Exercise 6-7 days/week
- `very_active` - Physical job + exercise daily

---

## Support

For issues or questions:
- API Documentation: http://localhost:8000/docs
- Health Check: http://localhost:8000/health
- GitHub Issues: https://github.com/minmcho/radiant-vision-app/issues

---

**Built with ❤️ by NutriVision AI**
