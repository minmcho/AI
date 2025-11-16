# NutriVision AI - Complete Feature Summary

## 🎉 What's New - User Authentication & Smart Nutrition

This update transforms NutriVision AI into a complete personalized nutrition platform with user accounts and intelligent meal planning.

---

## ✨ New Features

### 1. User Registration & Authentication

#### Complete Health Profile Registration
Register users with comprehensive health information:

```bash
POST /auth/register
{
  "email": "user@example.com",
  "username": "johndoe",
  "password": "SecurePass123!",

  # Health Metrics
  "age": 30,
  "weight_kg": 75.5,
  "height_cm": 175,
  "sex": "male",              # male/female/other

  # Dietary Information
  "allergies": ["peanuts", "shellfish"],
  "dietary_restrictions": ["vegetarian"],

  # Goals
  "health_goals": ["weight_loss", "improve_fitness"],
  "activity_level": "moderate",  # sedentary/light/moderate/active/very_active

  # Optional Medical Info
  "medical_conditions": ["diabetes"],
  "medications": ["metformin"]
}
```

**Automatic Calculations:**
- ✅ BMI (Body Mass Index)
- ✅ Daily Calorie Target (Harris-Benedict equation)
- ✅ Macronutrient Ratios (protein/carbs/fat based on goals)

#### Secure Authentication System
- 🔐 **JWT Tokens** - Access token (30 min) + Refresh token (7 days)
- 🔒 **Bcrypt Password Hashing** - Industry-standard security
- 🛡️ **OAuth2 Password Flow** - Standard authentication pattern
- 🔄 **Token Refresh** - Seamless session management
- 🔑 **Password Change** - Secure password updates

**Endpoints:**
```
POST   /auth/register          - Create new account
POST   /auth/login             - Get JWT tokens
GET    /auth/me                - Get current user
POST   /auth/refresh           - Refresh access token
POST   /auth/change-password   - Update password
POST   /auth/logout            - Logout (client-side)
```

### 2. User Profile Management

#### Update Profile
Update any profile field with automatic recalculation:

```bash
PUT /profile/update
{
  "weight_kg": 73.0,                          # New weight
  "health_goals": ["weight_loss", "heart_health"],
  "activity_level": "active",                 # Increased activity
  "cuisine_preferences": ["mediterranean", "asian"]
}
```

**Auto-Updates:**
- Recalculates BMI
- Adjusts daily calorie target
- Updates macronutrient ratios

#### Health Summary
Get comprehensive overview of your health metrics:

```bash
GET /profile/health-summary
```

**Returns:**
- Current health metrics (BMI, weight, height, etc.)
- Nutrition targets (calories, protein, carbs, fat)
- Dietary profile (restrictions, allergies, goals)
- Medical information

### 3. Smart AI Nutrition Planning

#### 🤖 Multi-Agent Nutrition System

Three specialized AI agents work together to create personalized, safe meal plans:

**1. Macronutrient Calculator Agent**
- Calculates optimal protein/carbs/fat ratios
- Considers health goals and activity level
- Adapts for medical conditions (diabetes, etc.)
- Uses evidence-based formulas

**2. Personalized Nutrition Advisor Agent**
- Creates complete meal plans
- Uses your full health profile
- Respects all dietary restrictions
- Ensures nutritional adequacy
- Provides variety and balance

**3. Allergy Safety Specialist Agent**
- **CRITICAL ROLE**: Verifies all meals are allergen-free
- Checks every ingredient in every meal
- Identifies hidden allergens
- Suggests safe substitutions
- Provides safety verification report

#### Get Personalized Nutrition Recommendations

```bash
GET /profile/nutrition-recommendations
```

**AI analyzes your profile and provides:**
- Current nutrition assessment
- Specific recommendations for YOUR health goals
- Foods to emphasize
- Foods to limit/avoid
- Supplement recommendations (if needed)
- Lifestyle tips
- Timeline and expectations

**Example Response:**
```json
{
  "user_id": 1,
  "recommendations": "Based on your profile (30 years old, male, 73kg, 175cm, BMI 23.8),
                      here are your personalized recommendations:\n\n
                      CURRENT ASSESSMENT:\n
                      - Your BMI of 23.8 indicates you're at a healthy weight\n
                      - Your target of 2450 calories/day is appropriate for weight loss at your activity level\n\n
                      MACRONUTRIENT TARGETS:\n
                      - Protein: 214g/day (35%) - Higher protein supports weight loss\n
                      - Carbohydrates: 184g/day (30%) - Moderate carbs for energy\n
                      - Fats: 95g/day (35%) - Healthy fats for satiety\n\n
                      FOODS TO EMPHASIZE:\n
                      - Lean vegetarian proteins: tofu, tempeh, legumes, Greek yogurt\n
                      - High-fiber foods: vegetables, fruits, whole grains\n
                      - Healthy fats: avocado, nuts, olive oil\n
                      - Mediterranean diet staples: fish alternatives, vegetables, olive oil\n\n
                      FOODS TO LIMIT:\n
                      - Refined carbohydrates and sugars\n
                      - Processed foods high in sodium\n
                      - Saturated fats\n\n
                      SUPPLEMENTS TO CONSIDER:\n
                      - Vitamin B12 (important for vegetarians)\n
                      - Omega-3 (algae-based for vegetarians)\n
                      - Vitamin D if limited sun exposure\n\n
                      TIMELINE:\n
                      - Expect 0.5-1kg weight loss per week\n
                      - Sustainable and healthy pace\n
                      - Monitor energy levels and adjust as needed...",
  "bmi": 23.8,
  "bmi_category": "normal",
  "generated_by": "Personalized Nutrition Advisor"
}
```

#### Generate Personalized Meal Plan

```bash
POST /profile/generate-meal-plan?days=7
```

**Creates complete 7-day meal plan:**
- Breakfast, lunch, dinner, and snacks for each day
- Specific food items and portions
- Calorie counts per meal
- Total daily macros
- **Safety verification** - confirms allergen-free

**Example Meal Plan Output:**
```
DAY 1

Breakfast (7:00 AM, 450 calories):
- Greek yogurt parfait: 200g Greek yogurt, 30g granola, 100g mixed berries
- Green tea
Macros: 25g protein, 55g carbs, 12g fat

Mid-Morning Snack (10:00 AM, 150 calories):
- Apple with 15g almond butter
Macros: 4g protein, 18g carbs, 9g fat

Lunch (12:30 PM, 550 calories):
- Mediterranean quinoa bowl: 150g cooked quinoa, chickpeas, cucumber,
  tomatoes, feta, olive oil lemon dressing
- Mixed green salad
Macros: 22g protein, 62g carbs, 20g fat

Afternoon Snack (3:30 PM, 200 calories):
- Hummus (80g) with carrot and celery sticks
Macros: 8g protein, 24g carbs, 8g fat

Dinner (6:30 PM, 600 calories):
- Tofu stir-fry: 200g firm tofu, mixed vegetables (broccoli, peppers,
  snap peas), brown rice (150g cooked)
- Sesame oil and ginger sauce
Macros: 35g protein, 65g carbs, 18g fat

Evening Snack (8:00 PM, 150 calories):
- Handful of mixed nuts (30g)
Macros: 6g protein, 8g carbs, 13g fat

DAILY TOTALS: 2100 calories, 100g protein, 232g carbs, 80g fat

ALLERGY SAFETY CHECK: ✅ No peanuts, no shellfish detected. All meals verified safe.

---
DAY 2
...
```

**Agents Used:**
- Macronutrient Calculator
- Personalized Nutrition Advisor
- Allergy Safety Specialist

---

## 🔒 Security Features

### Password Security
- ✅ Minimum 8 characters enforced
- ✅ Bcrypt hashing (industry standard)
- ✅ Never stored in plain text
- ✅ Secure password change endpoint

### Token Security
- ✅ JWT with HS256 algorithm
- ✅ Access token: 30 minutes
- ✅ Refresh token: 7 days
- ✅ Signed with secret key
- ✅ Token refresh flow

### API Security
- ✅ CORS protection
- ✅ OAuth2 password flow
- ✅ Bearer token authentication
- ✅ SQL injection protection (SQLAlchemy ORM)

### Data Privacy
- ✅ User data encryption at rest
- ✅ Secure credential handling
- ✅ Privacy-first design

---

## 📊 Enhanced Data Models

### User Model Updates

**New Fields:**
```python
# Biological sex for accurate calorie calculation
sex: Enum["male", "female", "other"]

# Precise weight tracking
weight_kg: Float  # Changed from Integer

# Macronutrient targets
target_protein_g: Float
target_carbs_g: Float
target_fat_g: Float

# Medical information
medical_conditions: List[str]
medications: List[str]
```

**New Enums:**
```python
# Sex enum for calorie calculations
Sex: "male" | "female" | "other"

# Health goals
HealthGoal:
  - "weight_loss"
  - "weight_gain"
  - "muscle_gain"
  - "maintain_weight"
  - "improve_fitness"
  - "manage_diabetes"
  - "lower_cholesterol"
  - "heart_health"
  - "digestive_health"
  - "general_wellness"
```

---

## 📁 New Files

**Backend Services:**
- `backend/app/services/auth_service.py` - Authentication & user management
- `backend/app/agents/nutrition_agents.py` - Smart nutrition planning agents

**API Endpoints:**
- `backend/app/api/auth.py` - Authentication endpoints
- `backend/app/api/profile.py` - Profile management & AI features
- `backend/app/api/__init__.py` - API module initialization

**Documentation:**
- `AUTH_GUIDE.md` - Complete authentication guide with examples
- `FEATURE_SUMMARY.md` - This file

---

## 🚀 Quick Test

### 1. Start the Backend

```bash
# With Docker
docker-compose up -d

# Or manually
cd backend
uvicorn app.main:app --reload
```

### 2. Register a User

```bash
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "username": "testuser",
    "password": "TestPass123!",
    "age": 30,
    "weight_kg": 75,
    "height_cm": 175,
    "sex": "male",
    "allergies": ["peanuts"],
    "health_goals": ["weight_loss"],
    "activity_level": "moderate"
  }'
```

### 3. Login

```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=test@example.com&password=TestPass123!"
```

Save the `access_token` from the response!

### 4. Get AI Nutrition Recommendations

```bash
curl -X GET http://localhost:8000/profile/nutrition-recommendations \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 5. Generate Personalized Meal Plan

```bash
curl -X POST "http://localhost:8000/profile/generate-meal-plan?days=7" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## 📖 Documentation

- **AUTH_GUIDE.md** - Complete authentication guide
  - Registration with all profile options
  - Login and token management
  - Profile updates
  - AI nutrition features
  - Python & JavaScript examples

- **README.md** - Updated with authentication section
- **ARCHITECTURE.md** - System architecture (unchanged)
- **SETUP.md** - Setup guide (unchanged)

---

## 🎯 Use Cases

### Weight Loss Journey
1. Register with current weight and "weight_loss" goal
2. Get personalized calorie target (auto-calculated)
3. Get AI nutrition recommendations
4. Generate weekly meal plan
5. Update weight weekly to adjust calorie targets

### Allergy-Safe Meal Planning
1. Register with allergies (e.g., peanuts, shellfish)
2. Generate meal plan
3. **AI agents verify every ingredient is safe**
4. Get safety verification report
5. Enjoy allergen-free meals with confidence

### Diabetic Meal Planning
1. Register with "manage_diabetes" goal
2. Add "diabetes" to medical conditions
3. Get specialized nutrition recommendations
4. Generate meal plans optimized for blood sugar control
5. Track progress and adjust

### Muscle Gain & Fitness
1. Register with "muscle_gain" goal
2. Set activity level to "active" or "very_active"
3. Get high-protein meal recommendations
4. Generate meal plans with optimal macro ratios
5. Update profile as fitness improves

---

## 💡 Technical Highlights

### Automatic Calorie Calculation

Uses **Harris-Benedict Equation**:
```python
# For males:
BMR = 88.362 + (13.397 × weight_kg) + (4.799 × height_cm) - (5.677 × age)

# For females:
BMR = 447.593 + (9.247 × weight_kg) + (3.098 × height_cm) - (4.330 × age)

# Adjusted for activity level:
Daily Calories = BMR × Activity Multiplier
```

**Activity Multipliers:**
- Sedentary: 1.2
- Light: 1.375
- Moderate: 1.55
- Active: 1.725
- Very Active: 1.9

### Macronutrient Calculation

Based on health goals:

**Weight Loss:**
- Protein: 35% (promotes satiety)
- Carbs: 30% (moderate)
- Fat: 35% (healthy fats for satiety)

**Muscle Gain:**
- Protein: 30% (muscle building)
- Carbs: 40% (energy for workouts)
- Fat: 30% (hormonal balance)

**Keto Diet:**
- Protein: 25%
- Carbs: 5% (ketosis)
- Fat: 70% (primary fuel)

**Balanced:**
- Protein: 25%
- Carbs: 45%
- Fat: 30%

---

## 🌟 What's Next?

Future enhancements:
- [ ] Email verification
- [ ] Password reset via email
- [ ] Two-factor authentication (2FA)
- [ ] Social login (Google, Facebook)
- [ ] Meal plan history
- [ ] Progress tracking dashboard
- [ ] Recipe favorites
- [ ] Grocery list export to shopping apps
- [ ] Integration with fitness trackers
- [ ] Mobile app (React Native)

---

## 📞 Support

- **API Docs**: http://localhost:8000/docs
- **Auth Guide**: AUTH_GUIDE.md
- **Health Check**: http://localhost:8000/health
- **GitHub**: https://github.com/minmcho/radiant-vision-app

---

**NutriVision AI** - Your Personal AI Nutrition Coach 🥗🤖

Built with intelligence, care, and a commitment to your health.
