# NutriVision AI - System Architecture

## Overview
AI-powered meal planning, nutrition tracking, and culinary assistant application using multi-agent systems and advanced AI models.

## Technology Stack

### Backend
- **FastAPI**: High-performance Python web framework
- **GraphQL**: Flexible query language via Strawberry GraphQL
- **PostgreSQL**: Relational database for structured data
- **ChromaDB**: Vector database for embeddings and similarity search

### AI/ML Models
- **LLaMA 3.2**: Primary LLM for conversational AI and text generation
- **CrewAI**: Multi-agent orchestration framework
- **Vision Transformers (ViT)**: Food image recognition and analysis
- **Sentence Transformers**: Text embeddings for semantic search
- **CLIP**: Cross-modal embeddings for image-text matching

### MCP Architecture
- **Model Context Protocol**: Shopping assistant integration
- **Context-aware agents**: Dynamic information retrieval

### External APIs
- **YouTube Data API v3**: Recipe video recommendations
- **Social Media APIs**: TikTok, Instagram (content discovery)
- **Nutrition APIs**: USDA FoodData Central, Edamam

## System Components

### 1. Multi-Agent System (CrewAI)

#### Agent Roles:
- **Meal Planning Agent**: Creates personalized meal plans (daily/weekly)
- **Nutrition Advisor Agent**: Analyzes nutritional content and provides recommendations
- **Recipe Discovery Agent**: Finds and suggests recipes based on preferences
- **Shopping Assistant Agent**: Generates shopping lists with MCP integration
- **Cooking Coach Agent**: Provides step-by-step cooking guidance
- **Cultural Cuisine Agent**: Analyzes and compares meals across countries
- **Beverage Sommelier Agent**: Recommends drinks/beverages for meals

### 2. Database Schema (PostgreSQL)

#### Core Tables:
- `users`: User profiles, preferences, dietary restrictions
- `meals`: Meal records with metadata
- `recipes`: Recipe details, ingredients, instructions
- `ingredients`: Ingredient database with nutritional info
- `meal_plans`: Weekly/daily meal planning schedules
- `user_meals`: User meal history and ratings
- `journal_entries`: Meal journaling and notes
- `shopping_lists`: Generated shopping lists
- `beverage_pairings`: Drink recommendations
- `social_posts`: Shared content and interactions

### 3. Vector Database (ChromaDB)

#### Collections:
- **recipe_embeddings**: Sentence transformer embeddings for recipes
- **meal_images**: Vision transformer embeddings for food images
- **ingredient_embeddings**: Semantic ingredient similarity
- **cross_cultural_meals**: Multi-lingual meal embeddings
- **cooking_instructions**: Semantic search for cooking steps

### 4. API Architecture

#### GraphQL Schema:
```graphql
type Query {
  # User queries
  me: User
  mealPlan(userId: ID!, startDate: Date!, days: Int!): [MealPlan]

  # Recipe queries
  recipes(filters: RecipeFilters): [Recipe]
  similarRecipes(recipeId: ID!, limit: Int): [Recipe]

  # Meal similarity
  similarMealsAcrossCountries(mealId: ID!): [CountryMealMatch]

  # Recommendations
  beverageRecommendations(mealId: ID!): [Beverage]
  videoRecommendations(recipeId: ID!): [Video]

  # Shopping
  generateShoppingList(mealPlanId: ID!): ShoppingList

  # Nutrition
  nutritionAnalysis(mealId: ID!): NutritionReport
}

type Mutation {
  # Meal planning
  createMealPlan(input: MealPlanInput!): MealPlan

  # Journaling
  createJournalEntry(input: JournalInput!): JournalEntry

  # Social
  shareToSocial(input: SocialShareInput!): SocialPost

  # AI interactions
  chatWithCookingAssistant(message: String!): ChatResponse
  analyzefoodImage(image: Upload!): FoodAnalysis
}
```

## AI Model Integration

### 1. LLaMA 3.2 Integration
- **Use Cases**: Conversational AI, recipe generation, cooking tips
- **Deployment**: Ollama or vLLM for local inference
- **Context**: RAG with recipe database and user preferences

### 2. Vision Transformer
- **Model**: Google ViT or CLIP for food recognition
- **Tasks**:
  - Food identification from images
  - Portion size estimation
  - Freshness assessment
  - Plating analysis

### 3. Sentence Transformers
- **Model**: all-MiniLM-L6-v2 or multilingual variants
- **Tasks**:
  - Recipe similarity search
  - Cross-cultural meal matching
  - Ingredient substitution recommendations

## Feature Modules

### 1. Meal Planning (Daily/Weekly)
- AI-generated meal plans based on:
  - Dietary restrictions
  - Caloric goals
  - Cuisine preferences
  - Available ingredients
  - Budget constraints

### 2. Cross-Country Meal Similarity
- Semantic embeddings of cuisines
- Cultural recipe mapping
- Ingredient equivalency across regions

### 3. Beverage Pairing
- ML-based drink recommendations
- Cultural pairing traditions
- Nutritional complementarity

### 4. MCP Shopping Assistant
- Real-time price comparison
- Store inventory integration
- Smart substitution suggestions
- Budget optimization

### 5. Video Discovery
- YouTube recipe tutorials
- TikTok/Instagram cooking videos
- Relevance ranking with CLIP embeddings

### 6. Cooking Assistant
- Real-time cooking guidance
- Timer management
- Technique explanations
- Troubleshooting help

### 7. Journaling & Social
- Meal photo uploads with automatic tagging
- Nutrition tracking visualization
- Social feed of shared meals
- Community recipe contributions

### 8. Diet & Nutrition Planning
- Macro/micronutrient tracking
- Health goal monitoring
- Medical dietary restrictions
- Personalized recommendations

## Deployment Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Frontend (Next.js)                  │
│  - React Components                                  │
│  - Apollo Client (GraphQL)                           │
│  - Real-time subscriptions                           │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│              FastAPI + GraphQL Server                │
│  - Strawberry GraphQL                                │
│  - WebSocket support                                 │
│  - Authentication (JWT)                              │
└─┬──────────┬──────────┬──────────┬──────────────────┘
  │          │          │          │
  ▼          ▼          ▼          ▼
┌────────┐ ┌─────┐ ┌────────┐ ┌──────────────────┐
│PostgreSQL ChromaDB│ CrewAI │ │  AI Models       │
│        │ │     │ │ Agents │ │  - LLaMA 3.2     │
└────────┘ └─────┘ └────────┘ │  - ViT           │
                               │  - Transformers  │
                               └──────────────────┘
```

## Security & Privacy
- User data encryption at rest
- GDPR compliance for EU users
- Secure API authentication (OAuth2 + JWT)
- Rate limiting and DDoS protection
- PII anonymization in AI training

## Scalability Considerations
- Horizontal scaling with load balancers
- Database replication and sharding
- Redis caching for frequent queries
- CDN for image/video content
- Async task queues (Celery) for AI operations
