# API and iOS App Comparison Report

**Generated:** 2025-11-16
**Purpose:** Comprehensive review of API-iOS consistency for NutriVision AI

---

## Executive Summary

This report identifies **12 critical discrepancies** between the backend API and iOS app that could cause runtime failures, incorrect behavior, or data inconsistencies.

### Severity Levels:
- 🔴 **CRITICAL** - Will cause failures or data loss
- 🟠 **HIGH** - May cause failures in specific scenarios
- 🟡 **MEDIUM** - Causes inconsistency but may work
- 🟢 **LOW** - Minor issues or improvements needed

---

## 🔴 CRITICAL ISSUES

### 1. Login Response Missing User Data
**Severity:** 🔴 CRITICAL
**Impact:** iOS app cannot get user profile after login

**iOS Expectation:**
```swift
// ios-app/NutriVisionAI/Models/User.swift:218-230
struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let user: User  // ❌ Expects user object
}
```

**API Implementation:**
```python
# backend/app/api/auth.py:40-43
class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    # ❌ No user field!
```

**Fix Required:**
API must include user data in login response OR iOS must make separate `/auth/me` call after login.

---

### 2. Refresh Token Endpoint Parameter Mismatch
**Severity:** 🔴 CRITICAL
**Impact:** Token refresh will fail - users will be logged out

**iOS Implementation:**
```swift
// ios-app/NutriVisionAI/Services/APIClient.swift:205-210
let response: TokenResponse = try await request(
    endpoint: Config.Endpoints.refreshToken,  // "/auth/refresh"
    method: "POST",
    body: RefreshTokenRequest(refreshToken: refreshToken),  // ❌ Sends as body
    requiresAuth: false
)
```

**API Implementation:**
```python
# backend/app/api/auth.py:182-186
@router.post("/refresh", response_model=Token)
async def refresh_token(
    refresh_token: str,  # ❌ Expects as query/path parameter, not body!
    db: AsyncSession = Depends(get_db)
):
```

**Fix Required:**
API should accept refresh_token in request body:
```python
class RefreshTokenRequest(BaseModel):
    refresh_token: str

async def refresh_token(
    request: RefreshTokenRequest,  # Accept body
    db: AsyncSession = Depends(get_db)
):
```

---

### 3. Social Post Endpoint URL Mismatch
**Severity:** 🔴 CRITICAL
**Impact:** Creating social posts will return 404 error

**iOS Implementation:**
```swift
// ios-app/NutriVisionAI/Services/MealPlanService.swift:152
return try await apiClient.request(
    endpoint: "\(Config.Endpoints.mealPlans)/social",  // "/meals/plans/social" ❌
    method: "POST",
    body: postRequest
)
```

**API Implementation:**
```python
# backend/app/api/meals.py:363
@router.post("/social", response_model=SocialPostResponse, ...)
# Actual endpoint: /meals/social ✓ (not /meals/plans/social)
```

**Fix Required:**
iOS should use `/meals/social` not `/meals/plans/social`

---

### 4. Meal Plan Generation Parameter Type Mismatch
**Severity:** 🔴 CRITICAL
**Impact:** AI meal plan generation will fail

**iOS Implementation:**
```swift
// ios-app/NutriVisionAI/Services/MealPlanService.swift:29-36
func generateMealPlan(days: Int = 7, preferences: [String: String]? = nil) async throws -> MealPlan {
    let request = GenerateMealPlanRequest(days: days, preferences: preferences)

    return try await apiClient.request(
        endpoint: Config.Endpoints.generateMealPlan,  // "/profile/generate-meal-plan"
        method: "POST",
        body: request  // ❌ Sends days in body
    )
}
```

**API Implementation:**
```python
# backend/app/api/profile.py:141-146
@router.post("/generate-meal-plan", response_model=PersonalizedMealPlanResponse)
async def generate_personalized_meal_plan(
    days: int = 7,  # ❌ Expects as query parameter!
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
```

**Fix Required:**
iOS should send days as query parameter:
```swift
endpoint: "\(Config.Endpoints.generateMealPlan)?days=\(days)"
```

OR API should accept body:
```python
class MealPlanRequest(BaseModel):
    days: int = 7

async def generate_personalized_meal_plan(
    request: MealPlanRequest,
    ...
)
```

---

## 🟠 HIGH PRIORITY ISSUES

### 5. Recipe Model Field Name Mismatches
**Severity:** 🟠 HIGH
**Impact:** Recipe display will show incorrect/missing data

**iOS Model:**
```swift
// ios-app/NutriVisionAI/Models/Recipe.swift:17-18
struct Recipe: Codable, Identifiable {
    let prepTime: Int?       // ❌ Wrong field name
    let cookTime: Int?       // ❌ Wrong field name
    // Missing: totalTime
```

**API Response:**
```python
# backend/app/api/recipes.py:41-49
class RecipeResponse(BaseModel):
    prep_time_minutes: int   // ✓ Correct
    cook_time_minutes: int   // ✓ Correct
    total_time_minutes: int  // ✓ But iOS doesn't have this!
```

**Fix Required:**
iOS CodingKeys should map correctly:
```swift
enum CodingKeys: String, CodingKey {
    case prepTime = "prep_time_minutes"
    case cookTime = "cook_time_minutes"
    case totalTime = "total_time_minutes"
    // ...
}
```

---

### 6. Recipe Search Filter Parameters Not Supported
**Severity:** 🟠 HIGH
**Impact:** Advanced recipe filtering won't work

**iOS Implementation:**
```swift
// ios-app/NutriVisionAI/Services/RecipeService.swift:81-101
func filterRecipes(
    cuisine: String? = nil,
    difficulty: String? = nil,
    maxCalories: Int? = nil,              // ❌ Not supported by API
    dietaryRestrictions: [DietaryRestriction]? = nil  // ❌ Wrong param name
) async throws -> [Recipe]
```

**API Implementation:**
```python
# backend/app/api/recipes.py:134-141
async def search_recipes(
    query: str = Query(..., min_length=2),
    cuisine: Optional[str] = None,
    max_prep_time: Optional[int] = None,   // ✓ Supported
    dietary_tags: Optional[List[str]] = Query(None),  // ✓ But named differently
    limit: int = Query(20, le=100),
    db: AsyncSession = Depends(get_db)
):
    # ❌ No max_calories filter!
```

**Fix Required:**
1. iOS should use `dietary_tags` not `dietaryRestrictions`
2. iOS should use `max_prep_time` not `maxCalories` (or API should add max_calories)
3. Remove unsupported filters from iOS or add to API

---

### 7. Missing User Fields in API Response
**Severity:** 🟠 HIGH
**Impact:** iOS may expect fields that don't exist

**iOS User Model Has:**
```swift
// ios-app/NutriVisionAI/Models/User.swift:12-46
struct User: Codable, Identifiable {
    var avatarUrl: String?          // ❌ Not in API
    var bio: String?                // ❌ Not in API
    var targetProteinG: Double?     // ❌ Not in API
    var targetCarbsG: Double?       // ❌ Not in API
    var targetFatG: Double?         // ❌ Not in API
    var cuisinePreferences: [String]?  // ❌ Not in UserResponse
    var dislikedIngredients: [String]? // ❌ Not in UserResponse
    var timezone: String?           // ❌ Not in API
    var isPremium: Bool?            // ❌ Not in API
```

**API UserResponse:**
```python
# backend/app/api/auth.py:46-61
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
    bmi: Optional[float]            // ✓ Calculated, not stored
    bmi_category: Optional[str]     // ✓ Calculated
    allergies: List[str]
    dietary_restrictions: List[str]
    health_goals: List[str]
    # ❌ Missing many iOS fields!
```

**Fix Required:**
Either:
1. Add missing fields to API UserResponse
2. Remove unused fields from iOS User model
3. Make iOS fields optional and handle gracefully when missing

---

## 🟡 MEDIUM PRIORITY ISSUES

### 8. Authentication Header Inconsistency
**Severity:** 🟡 MEDIUM
**Impact:** May cause confusion but should work

**iOS Implementation:**
```swift
// ios-app/NutriVisionAI/Services/APIClient.swift:72
request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
```

**API Implementation:**
```python
# backend/app/api/auth.py:15
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")
# Expects: "Authorization: Bearer <token>" ✓
```

**Status:** ✓ Compatible - Both use "Bearer" scheme correctly

---

### 9. Journal Entry Model Mismatch
**Severity:** 🟡 MEDIUM
**Impact:** Journal functionality may not work correctly

**iOS Model:**
```swift
// ios-app/NutriVisionAI/Models/Recipe.swift:176-186
struct JournalEntry: Codable, Identifiable {
    let id: Int
    let userId: Int
    let mealType: MealType     // ✓
    let description: String    // ✓
    let imageUrl: String?      // ❌ API uses photo_urls: List[str]
    let calories: Double?      // ❌ Not in API
    let mood: String?          // ✓
    let notes: String?         // ❌ API uses content: str (different field)
    let createdAt: String      // ✓
}
```

**API Model:**
```python
# backend/app/api/meals.py:50-72
class JournalEntryCreate(BaseModel):
    title: str                    // ❌ iOS doesn't have this
    content: str                  // ✓ (iOS uses notes?)
    meal_date: datetime           // ❌ iOS doesn't send this
    mood: Optional[str] = None    // ✓
    satisfaction: Optional[int] = None  // ❌ iOS doesn't have this
    tags: List[str] = []          // ❌ iOS doesn't have this
    photo_urls: List[str] = []    // ✓ (iOS uses imageUrl singular)
```

**Fix Required:**
Significant model mismatch - needs alignment:
1. Decide on single image vs multiple images
2. Align field names (content vs notes vs description)
3. Add missing fields to both sides

---

### 10. Ingredient Model Field Mismatch
**Severity:** 🟡 MEDIUM
**Impact:** Recipe ingredients may not display correctly

**iOS Model:**
```swift
// ios-app/NutriVisionAI/Models/Recipe.swift:46-58
struct Ingredient: Codable, Identifiable {
    let id: Int?
    let recipeId: Int?
    let name: String
    let amount: Double?    // ❌ API uses quantity: float
    let unit: String?      // ✓
    let notes: String?     // ❌ API doesn't have this
}
```

**API Model:**
```python
# backend/app/api/recipes.py:19-22
class IngredientCreate(BaseModel):
    name: str
    quantity: float       // ✓ (iOS calls it amount)
    unit: str             // ✓
```

**Fix Required:**
iOS CodingKeys should map `amount` to `quantity`

---

### 11. Video Model and Response Mismatch
**Severity:** 🟠 HIGH (Promoted from MEDIUM)
**Impact:** Video features will fail - cannot deserialize API responses

**iOS Video Model:**
```swift
// ios-app/NutriVisionAI/Models/Video.swift:12-33
struct Video: Codable, Identifiable {
    let id: String            // ❌ API uses video_id
    let videoUrl: String      // ❌ API uses url
    let creator: String?      // ❌ API uses channel_name
    let createdAt: String?    // ❌ API doesn't have this
    // Missing: channelUrl, likeCount, relevanceScore
}
```

**API VideoResponse:**
```python
# backend/app/api/videos.py:15-27
class VideoResponse(BaseModel):
    platform: str             // ✓
    video_id: str             // ❌ iOS uses id
    title: str                // ✓
    description: str          // ✓
    url: str                  // ❌ iOS uses videoUrl
    thumbnail_url: str        // ✓ iOS has thumbnailUrl
    channel_name: str         // ❌ iOS uses creator
    channel_url: str          // ❌ iOS doesn't have this
    view_count: int           // ✓ iOS has viewCount
    like_count: int           // ❌ iOS doesn't have this
    duration: str             // ✓ (but iOS uses Int?)
    relevance_score: Optional[float] = None  // ❌ iOS doesn't have this
```

**iOS Search/Trending Response Mismatch:**
```swift
// ios-app/NutriVisionAI/Services/VideoService.swift:24-38
func searchVideos(...) async throws -> VideoSearchResponse {
    // ❌ Expects VideoSearchResponse with pagination
}

func getTrendingVideos(...) async throws -> [Video] {
    // ❌ Expects array of Video
}
```

**API Actual Responses:**
```python
# backend/app/api/videos.py:77
@router.get("/search", response_model=List[VideoResponse])
# ❌ Returns List[VideoResponse], not paginated object!

# backend/app/api/videos.py:106
@router.get("/trending", response_model=TrendingVideosResponse)
# ❌ Returns TrendingVideosResponse with videos, cuisine, total_count
```

**Fix Required:**
1. Map iOS Video fields using CodingKeys: id→video_id, videoUrl→url, creator→channel_name
2. Fix searchVideos to return `[Video]` not `VideoSearchResponse`
3. Create iOS model for TrendingVideosResponse or change getTrendingVideos
4. Add missing fields: channelUrl, likeCount, relevanceScore
5. Change duration from Int? to String?

---

### 12. Shopping List Quantity Type Mismatch
**Severity:** 🔴 CRITICAL (Promoted from MEDIUM)
**Impact:** Shopping list creation will fail with type error

**iOS Model:**
```swift
// ios-app/NutriVisionAI/Models/Recipe.swift:216-229
struct ShoppingListItem: Codable, Identifiable {
    let id: Int
    let listId: Int
    let name: String
    let quantity: String?      // ❌ String type!
    let unit: String?
    let category: String?
    var isPurchased: Bool
}
```

**API Model:**
```python
# backend/app/api/shopping.py:19-23
class ShoppingItemCreate(BaseModel):
    name: str
    quantity: float           # ✓ Expects numeric type!
    unit: str
    category: Optional[str] = "other"
```

**API Response:**
```python
# backend/app/api/shopping.py:34-46
class ShoppingItemResponse(BaseModel):
    id: int
    name: str
    quantity: float           # ✓ Returns numeric
    unit: str
    category: str
    estimated_price: Optional[float]   # ❌ iOS doesn't have this
    actual_price: Optional[float]      # ❌ iOS doesn't have this
    is_purchased: bool
    substitution_suggestions: List[dict]  # ❌ iOS doesn't have this
```

**Fix Required:**
1. **CRITICAL:** Change iOS quantity to `Double` not `String`
2. Add missing fields to iOS model: `estimatedPrice`, `actualPrice`, `substitutionSuggestions`
3. Update iOS ShoppingList to include `totalEstimatedCost` field

---

## 🟢 LOW PRIORITY / INFORMATIONAL

### 13. BLIP Model Responses Match Correctly
**Status:** ✓ PASS

**iOS Models:**
```swift
// ios-app/NutriVisionAI/Models/Recipe.swift:143-172
struct BlipCaptionResponse: Codable { ... }  // ✓
struct BlipVQAResponse: Codable { ... }      // ✓
struct BlipFoodAnalysisResponse: Codable { ... }  // ✓
```

**API Models:**
```python
# backend/app/api/ai.py:377-411
class ImageCaptionResponse(BaseModel): ...   // ✓
class VisualQuestionResponse(BaseModel): ... // ✓
class BlipFoodAnalysisResponse(BaseModel): ... // ✓
```

All BLIP models match correctly! ✓

---

### 14. Speech Models Match Correctly
**Status:** ✓ PASS

**iOS Models:**
```swift
// ios-app/NutriVisionAI/Models/Speech.swift
TranscriptionRequest/Response  // ✓ Matches API
SynthesisRequest/Response      // ✓ Matches API
VoiceCommandRequest/Response   // ✓ Matches API
TranslationRequest/Response    // ✓ Matches API
LanguageInfo                   // ✓ Matches API
```

All speech models are correctly aligned! ✓

---

## Summary Statistics

| Category | Count |
|----------|-------|
| 🔴 Critical Issues | 5 |
| 🟠 High Priority | 4 |
| 🟡 Medium Priority | 3 |
| 🟢 Low/Info | 2 |
| ✓ Passing | Many |
| **Total Issues** | **14** |

---

## Recommendations

### Immediate Actions (Critical):
1. **Fix login response** - Add user object to Token response
2. **Fix refresh token endpoint** - Accept body parameter
3. **Fix social post URL** - Update iOS to use `/meals/social`
4. **Fix meal plan generation** - Align parameter passing
5. **Fix shopping list quantity type** - Change iOS String to Double

### High Priority Actions:
6. **Align Recipe model** - Fix field name mapping
7. **Fix recipe filtering** - Remove unsupported filters or add to API
8. **Align User model** - Add missing fields or remove from iOS
9. **Fix Video model and responses** - Align field mappings and response types

### Medium Priority:
10. **Fix Journal Entry model** - Complete redesign/alignment needed
11. **Fix Ingredient model** - Map amount ↔ quantity

### Best Practices Going Forward:
- Use shared OpenAPI/Swagger spec for both frontend and backend
- Implement integration tests that verify request/response formats
- Use TypeScript/Kotlin instead of manual Swift models (codegen from OpenAPI)
- Add API versioning to handle breaking changes
- Document all breaking changes in CHANGELOG

---

## Testing Recommendations

### Integration Tests Needed:
```bash
# Test critical paths:
1. Login flow → Verify user data returned
2. Token refresh → Verify body parameter accepted
3. Social post creation → Verify endpoint exists
4. Meal plan generation → Verify parameter format
5. Recipe search → Verify filter parameters
6. Journal entry CRUD → Verify model compatibility
```

### API Contract Tests:
Consider using tools like:
- Pact (Consumer-Driven Contract Testing)
- OpenAPI Validator
- Postman/Newman for automated API testing

---

**Report End**
