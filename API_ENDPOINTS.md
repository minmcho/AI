# NutriVision AI - Complete API Endpoints Reference

Comprehensive documentation for all API endpoints in NutriVision AI.

## Base URL
```
http://localhost:8000
```

## Authentication
Most endpoints require JWT authentication. Include the access token in the `Authorization` header:
```
Authorization: Bearer <access_token>
```

---

## 📋 Table of Contents

1. [Authentication](#authentication-endpoints) - `/auth`
2. [User Profile](#user-profile-endpoints) - `/profile`
3. [Recipes](#recipe-endpoints) - `/recipes`
4. [AI Features](#ai-features-endpoints) - `/ai`
5. [Videos](#video-endpoints) - `/videos`
6. [Shopping](#shopping-endpoints) - `/shopping`
7. [Meals & Journaling](#meals--journaling-endpoints) - `/meals`
8. [Speech & Multi-language](#speech--multi-language-endpoints) - `/speech`
9. [GraphQL](#graphql-api) - `/graphql`

---

## Authentication Endpoints

### `POST /auth/register`
Register a new user with health profile.

**Body:**
```json
{
  "email": "user@example.com",
  "username": "username",
  "password": "SecurePass123!",
  "age": 30,
  "weight_kg": 75.5,
  "height_cm": 175,
  "sex": "male",
  "allergies": ["peanuts"],
  "dietary_restrictions": ["vegetarian"],
  "health_goals": ["weight_loss"],
  "activity_level": "moderate"
}
```

### `POST /auth/login`
Login and get JWT tokens.

**Form Data:**
- `username`: Email address
- `password`: Password

**Response:**
```json
{
  "access_token": "eyJhbGci...",
  "refresh_token": "eyJhbGci...",
  "token_type": "bearer"
}
```

### `GET /auth/me`
Get current user profile.

**Auth:** Required

### `POST /auth/refresh`
Refresh access token.

**Query:** `refresh_token`

### `POST /auth/change-password`
Change user password.

**Auth:** Required
**Body:** `current_password`, `new_password`

---

## User Profile Endpoints

### `PUT /profile/update`
Update user profile.

**Auth:** Required
**Body:** Any profile fields to update

### `GET /profile/health-summary`
Get comprehensive health metrics.

**Auth:** Required

### `GET /profile/nutrition-recommendations`
Get AI-powered personalized nutrition recommendations.

**Auth:** Required
**Returns:** Detailed nutrition advice from AI agents

### `POST /profile/generate-meal-plan`
Generate personalized meal plan using multi-agent AI.

**Auth:** Required
**Query:** `days` (1-30, default: 7)
**Returns:** Complete meal plan with safety verification

---

## Recipe Endpoints

### `POST /recipes/`
Create a new recipe.

**Auth:** Required
**Body:**
```json
{
  "name": "Pasta Carbonara",
  "description": "Classic Italian pasta",
  "cuisine": "Italian",
  "country_origin": "Italy",
  "prep_time_minutes": 10,
  "cook_time_minutes": 20,
  "servings": 4,
  "difficulty": "medium",
  "instructions": ["Step 1...", "Step 2..."],
  "ingredients": [
    {"name": "pasta", "quantity": 400, "unit": "g"},
    {"name": "eggs", "quantity": 4, "unit": "whole"}
  ],
  "tags": ["dinner", "italian"],
  "dietary_tags": []
}
```

### `GET /recipes/search`
Search recipes by text query.

**Query Parameters:**
- `query`: Search term (required)
- `cuisine`: Filter by cuisine
- `max_prep_time`: Maximum prep time
- `dietary_tags`: List of dietary tags
- `limit`: Max results (default: 20, max: 100)

**Example:**
```
GET /recipes/search?query=pasta&cuisine=Italian&max_prep_time=30
```

### `GET /recipes/similar/{recipe_id}`
Find similar recipes using AI embeddings.

**Query:** `limit` (default: 10, max: 50)
**Returns:** Recipes with similar ingredients, flavors, and cuisines

### `GET /recipes/{recipe_id}`
Get recipe details by ID.

### `GET /recipes/`
List recipes with pagination.

**Query Parameters:**
- `skip`: Number to skip (default: 0)
- `limit`: Max results (default: 20, max: 100)
- `cuisine`: Filter by cuisine
- `sort_by`: `rating` | `views` | `recent`

### `GET /recipes/by-cuisine/{cuisine}`
Get recipes by cuisine type.

### `GET /recipes/by-country/{country}`
Get recipes by country of origin.

### `GET /recipes/cuisines/list`
Get list of all available cuisines with counts.

### `DELETE /recipes/{recipe_id}`
Delete a recipe.

**Auth:** Required

---

## AI Features Endpoints

### `POST /ai/chat/cooking-assistant`
Chat with AI cooking assistant.

**Auth:** Required
**Body:**
```json
{
  "message": "How do I know when pasta is al dente?",
  "context": {
    "current_recipe": "Pasta Carbonara"
  }
}
```

**Returns:**
```json
{
  "message": "Pasta is al dente when...",
  "agent_name": "Cooking Assistant",
  "suggestions": ["Taste test", "Check texture"],
  "confidence": 0.9
}
```

### `POST /ai/analyze-food-image`
Analyze food image using Vision Transformer.

**Auth:** Required
**Body:**
```json
{
  "image_data": "data:image/jpeg;base64,/9j/4AAQ..."
}
```

**Returns:**
```json
{
  "food_items": ["salmon", "asparagus", "rice"],
  "estimated_calories": 450.0,
  "detected_ingredients": ["fish", "vegetable", "grain"],
  "cuisine_type": "Western",
  "confidence": 0.85
}
```

### `POST /ai/analyze-food-image/upload`
Analyze food image via file upload.

**Auth:** Required
**Form Data:** `file` (image file)
**Accepts:** JPEG, PNG, WebP (max 10MB)

### `POST /ai/cultural-similarity`
Find similar dishes across different cultures.

**Auth:** Required
**Body:**
```json
{
  "meal_description": "Italian pasta carbonara",
  "target_cuisines": ["French", "Chinese", "Mexican"]
}
```

**Returns:** AI analysis of similar dishes in target cuisines

### `POST /ai/beverage-pairing`
Get AI beverage pairing recommendations.

**Auth:** Required
**Body:**
```json
{
  "meal_description": "Grilled salmon with lemon butter",
  "preferences": {
    "alcohol": "wine",
    "budget": "moderate"
  }
}
```

**Returns:** 3 beverage recommendations with explanations

### `GET /ai/explain-technique/{technique}`
Get explanation of a cooking technique.

**Auth:** Required
**Path:** technique name (e.g., "sautéing", "braising")

### `POST /ai/ingredient-substitutes`
Find ingredient substitutes using AI.

**Auth:** Required
**Query:** `ingredient`
**Returns:** List of suitable substitutes with similarity scores

### `POST /ai/meal-plan/ai-generate`
Generate AI meal plan using full multi-agent system.

**Auth:** Required
**Query:** `days`, `preferences`

### `POST /ai/blip/caption`
Generate natural language caption for food image using BLIP.

**Auth:** Required
**Body:**
```json
{
  "image_data": "data:image/jpeg;base64,/9j/4AAQ...",
  "max_length": 50,
  "num_beams": 3,
  "conditional_text": null
}
```

**Returns:**
```json
{
  "caption": "a plate of pasta carbonara with bacon and parmesan cheese",
  "confidence": 0.9,
  "model": "BLIP"
}
```

**Features:**
- Natural language image descriptions
- Conditional caption generation
- High-quality beam search

**Use Cases:**
- Recipe documentation
- Alt text generation
- Food blog content
- Social media captions

### `POST /ai/blip/caption/upload`
Generate caption from uploaded image file.

**Auth:** Required
**Form Data:** `file` (image file)
**Query:** `max_length`, `num_beams`, `conditional_text`
**Accepts:** JPG, PNG, WEBP (max 10MB)

### `POST /ai/blip/vqa`
Answer questions about food images using BLIP Visual Question Answering.

**Auth:** Required
**Body:**
```json
{
  "image_data": "data:image/jpeg;base64,/9j/4AAQ...",
  "question": "What type of food is this?",
  "max_length": 50
}
```

**Returns:**
```json
{
  "question": "What type of food is this?",
  "answer": "pasta carbonara",
  "confidence": 0.9,
  "model": "BLIP-VQA"
}
```

**Example Questions:**
- "What type of food is this?"
- "What are the main ingredients?"
- "How is this food cooked?"
- "What cuisine is this?"
- "How many servings?"

**Use Cases:**
- Ingredient identification
- Dietary restriction checking
- Cuisine classification
- Portion estimation

### `POST /ai/blip/vqa/upload`
Answer questions about uploaded image file.

**Auth:** Required
**Form Data:** `file` (image file)
**Query:** `question`, `max_length`

### `POST /ai/blip/analyze-food`
Comprehensive food analysis combining BLIP captioning and VQA.

**Auth:** Required
**Body:**
```json
{
  "image_data": "data:image/jpeg;base64,/9j/4AAQ..."
}
```

**Returns:**
```json
{
  "caption": "a delicious plate of pasta carbonara",
  "food_type": "pasta carbonara",
  "ingredients": "pasta, bacon, eggs, parmesan cheese",
  "cooking_method": "boiled pasta with sautéed bacon and cream sauce",
  "cuisine": "Italian",
  "servings": "1-2",
  "confidence": 0.85
}
```

**Features:**
- Runs multiple BLIP models for comprehensive analysis
- Structured output with 6 key attributes
- High accuracy on clear food images

**Processing:**
1. BLIP Captioning for description
2. BLIP VQA for food type
3. BLIP VQA for ingredients
4. BLIP VQA for cooking method
5. BLIP VQA for cuisine
6. BLIP VQA for servings

### `POST /ai/blip/analyze-food/upload`
Comprehensive food analysis from uploaded image file.

**Auth:** Required
**Form Data:** `file` (image file)

---

## Video Endpoints

### `GET /videos/recipe/{recipe_id}`
Get cooking videos for a specific recipe.

**Auth:** Required
**Query:** `limit` (default: 5, max: 20)
**Returns:** Curated YouTube and social media videos

### `GET /videos/search`
Search for cooking videos by keyword.

**Auth:** Required
**Query:**
- `query`: Search term (required)
- `limit`: Max results (default: 10, max: 20)

### `GET /videos/trending`
Get trending cooking videos.

**Auth:** Required
**Query:**
- `cuisine`: Filter by cuisine (optional)
- `limit`: Max results (default: 10, max: 20)

### `GET /videos/technique/{technique}`
Get tutorial videos for cooking techniques.

**Auth:** Required
**Query:** `limit` (default: 3, max: 10)

### `GET /videos/multi-platform/{recipe_name}`
Get videos from multiple platforms.

**Auth:** Required
**Query:** `max_per_platform` (default: 3, max: 5)
**Returns:** Videos from YouTube, TikTok, Instagram

---

## Shopping Endpoints

### `POST /shopping/`
Create a shopping list.

**Auth:** Required
**Body:**
```json
{
  "name": "Weekly Groceries",
  "items": [
    {
      "name": "tomatoes",
      "quantity": 5,
      "unit": "pieces",
      "category": "produce"
    }
  ],
  "preferred_stores": ["Whole Foods"],
  "budget_limit": 100.0
}
```

### `POST /shopping/from-meal-plan/{meal_plan_id}`
Generate shopping list from meal plan using MCP.

**Auth:** Required
**Returns:**
- Aggregated ingredients
- Price estimates
- Store optimization
- Substitution suggestions

### `GET /shopping/`
Get all shopping lists for current user.

**Auth:** Required

### `GET /shopping/{list_id}`
Get shopping list by ID.

**Auth:** Required

### `PATCH /shopping/{list_id}/items/{item_id}/purchased`
Mark shopping list item as purchased.

**Auth:** Required
**Query:**
- `purchased`: boolean
- `actual_price`: float (optional)

### `PATCH /shopping/{list_id}/complete`
Mark shopping list as completed.

**Auth:** Required

### `DELETE /shopping/{list_id}`
Delete shopping list.

**Auth:** Required

---

## Meals & Journaling Endpoints

### Meal Plans

#### `POST /meals/plans`
Create a meal plan.

**Auth:** Required
**Body:**
```json
{
  "name": "Week 1 Meal Plan",
  "start_date": "2024-01-01",
  "end_date": "2024-01-07",
  "daily_calorie_target": 2000
}
```

#### `GET /meals/plans`
Get all meal plans.

**Auth:** Required
**Query:** `active_only` (boolean)

#### `GET /meals/plans/{plan_id}`
Get meal plan by ID.

**Auth:** Required

#### `PATCH /meals/plans/{plan_id}/meals/{meal_id}/consume`
Mark meal as consumed.

**Auth:** Required
**Query:**
- `rating`: 1-5 (optional)
- `notes`: string (optional)

### Journal

#### `POST /meals/journal`
Create meal journal entry.

**Auth:** Required
**Body:**
```json
{
  "title": "Lunch at Cafe",
  "content": "Had a delicious salad...",
  "meal_date": "2024-01-15T12:30:00",
  "mood": "happy",
  "satisfaction": 8,
  "tags": ["lunch", "healthy"],
  "photo_urls": ["https://..."]
}
```

#### `GET /meals/journal`
Get journal entries.

**Auth:** Required
**Query:**
- `start_date`: date (optional)
- `end_date`: date (optional)
- `limit`: int (default: 50, max: 200)

#### `GET /meals/journal/{entry_id}`
Get journal entry by ID.

**Auth:** Required

#### `DELETE /meals/journal/{entry_id}`
Delete journal entry.

**Auth:** Required

### Social

#### `POST /meals/social`
Share to social feed.

**Auth:** Required
**Body:**
```json
{
  "caption": "My homemade pasta!",
  "recipe_id": 123,
  "photo_urls": ["https://..."],
  "hashtags": ["homemade", "italian"],
  "is_public": true
}
```

#### `GET /meals/social/feed`
Get community social feed.

**Auth:** Required
**Query:**
- `limit`: int (default: 20, max: 100)
- `offset`: int (default: 0)

#### `GET /meals/social/my-posts`
Get all posts from current user.

**Auth:** Required
**Query:** `limit` (default: 20, max: 100)

#### `POST /meals/social/{post_id}/like`
Like a social post.

**Auth:** Required

#### `DELETE /meals/social/{post_id}`
Delete social post.

**Auth:** Required

---

## Speech & Multi-language Endpoints

### `POST /speech/transcribe`
Convert audio to text using Whisper.

**Auth:** Required
**Body:**
```json
{
  "audio_base64": "base64_encoded_audio_data",
  "language": "en",
  "translate_to_english": false
}
```

**Returns:**
```json
{
  "text": "Transcribed text",
  "language": "en",
  "confidence": 0.95
}
```

**Supported Languages:**
- `en`: English
- `zh`: Chinese/Mandarin
- `ja`: Japanese
- `ko`: Korean
- `th`: Thai
- `my`: Myanmar/Burmese

### `POST /speech/transcribe/upload`
Upload audio file for transcription.

**Auth:** Required
**Form Data:** `file` (audio file)
**Query:** `language`, `translate_to_english`
**Accepts:** MP3, WAV, M4A, FLAC, OGG (max 25MB)

### `POST /speech/synthesize`
Convert text to speech using gTTS.

**Auth:** Required
**Body:**
```json
{
  "text": "Text to convert to speech",
  "language": "en",
  "slow": false
}
```

**Returns:**
```json
{
  "audio_base64": "base64_encoded_mp3_audio",
  "language": "en"
}
```

### `POST /speech/voice-command`
Process voice command with intent detection.

**Auth:** Required
**Body:**
```json
{
  "audio_base64": "base64_encoded_audio",
  "user_language": "en"
}
```

**Returns:**
```json
{
  "command": "Find recipe for pasta carbonara",
  "language": "en",
  "intent": "search_recipe",
  "parameters": {
    "query": "pasta carbonara"
  },
  "confidence": 0.9
}
```

**Supported Intents:**
- `search_recipe`: Find recipes
- `create_meal_plan`: Generate meal plans
- `get_nutrition_info`: Get nutritional information
- `analyze_food`: Analyze food from description
- `get_recommendations`: Get AI recommendations
- `add_to_shopping_list`: Add to shopping list
- `log_meal`: Log meal to journal
- `unknown`: Intent not recognized

### `POST /speech/voice-command/upload`
Upload audio file for voice command processing.

**Auth:** Required
**Form Data:** `file` (audio file)
**Query:** `user_language` (default: "en")

### `POST /speech/translate`
Translate text between languages using LLM.

**Auth:** Required
**Body:**
```json
{
  "text": "This pasta is delicious",
  "source_lang": "en",
  "target_lang": "ja"
}
```

**Returns:**
```json
{
  "translated_text": "このパスタは美味しいです",
  "source_lang": "en",
  "target_lang": "ja"
}
```

### `GET /speech/languages`
Get list of supported languages.

**Auth:** Required
**Returns:** List of supported languages with STT/TTS capabilities

### `GET /speech/detect-language`
Detect language from text.

**Auth:** Required
**Query:** `text`
**Returns:**
```json
{
  "detected_language": "en",
  "language_name": "English",
  "text": "Sample text"
}
```

---

## GraphQL API

### Endpoint
```
POST /graphql
```

### Playground
```
http://localhost:8000/graphql
```

### Example Query
```graphql
query {
  recipes(filters: {cuisine: "Italian", maxCalories: 600}) {
    id
    name
    cuisine
    calories
    rating
  }
}
```

### Example Mutation
```graphql
mutation {
  createMealPlan(input: {
    name: "Week 1"
    startDate: "2024-01-01"
    endDate: "2024-01-07"
    dailyCalorieTarget: 2000
  }) {
    id
    name
  }
}
```

---

## Interactive API Documentation

Visit the auto-generated interactive API docs:

**Swagger UI:**
```
http://localhost:8000/docs
```

**ReDoc:**
```
http://localhost:8000/redoc
```

---

## Response Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK - Request succeeded |
| 201 | Created - Resource created successfully |
| 204 | No Content - Resource deleted successfully |
| 400 | Bad Request - Invalid input data |
| 401 | Unauthorized - Authentication required or failed |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource not found |
| 500 | Internal Server Error - Server error |

---

## Rate Limiting

Currently no rate limiting is enforced. In production, implement:
- 100 requests per minute for authenticated users
- 10 requests per minute for unauthenticated endpoints

---

## Pagination

Endpoints that return lists support pagination:

```
GET /endpoint?skip=0&limit=20
```

- `skip`: Number of items to skip (default: 0)
- `limit`: Maximum items to return (varies by endpoint)

---

## Error Response Format

```json
{
  "detail": "Error message describing what went wrong"
}
```

---

## Quick Reference

### Most Used Endpoints

```bash
# Authentication
POST /auth/register
POST /auth/login
GET /auth/me

# Get Recommendations
GET /profile/nutrition-recommendations
POST /profile/generate-meal-plan?days=7

# Search Recipes
GET /recipes/search?query=pasta

# AI Chat
POST /ai/chat/cooking-assistant

# Analyze Food Image
POST /ai/analyze-food-image/upload

# Get Videos
GET /videos/recipe/{recipe_id}

# Shopping List
POST /shopping/from-meal-plan/{meal_plan_id}

# Journal
POST /meals/journal
GET /meals/journal

# Social
POST /meals/social
GET /meals/social/feed

# Speech & Multi-language
POST /speech/transcribe
POST /speech/synthesize
POST /speech/voice-command
POST /speech/translate
GET /speech/languages
```

---

## Support

- **Full API Docs**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health
- **Status**: http://localhost:8000/

---

**NutriVision AI** - Complete API for personalized nutrition and meal planning
