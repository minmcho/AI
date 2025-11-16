# Speech & Multi-language Features Guide

Complete guide for using speech-to-text, text-to-speech, voice commands, and multi-language features in NutriVision AI.

---

## 🌍 Supported Languages

NutriVision AI supports **6 languages** across all speech and translation features:

| Code | Language | Native Name | Features |
|------|----------|-------------|----------|
| `en` | English | English | STT, TTS, Voice Commands, Translation |
| `zh` | Chinese/Mandarin | 中文 | STT, TTS, Voice Commands, Translation |
| `ja` | Japanese | 日本語 | STT, TTS, Voice Commands, Translation |
| `ko` | Korean | 한국어 | STT, TTS, Voice Commands, Translation |
| `th` | Thai | ไทย | STT, TTS, Voice Commands, Translation |
| `my` | Myanmar/Burmese | မြန်မာ | STT, TTS, Voice Commands, Translation |

All languages support:
- ✅ Speech-to-Text (Whisper AI)
- ✅ Text-to-Speech (gTTS)
- ✅ Voice Command Recognition
- ✅ Intent Detection
- ✅ AI Translation

---

## 🎤 Speech-to-Text (STT)

Convert audio recordings to text using OpenAI Whisper.

### Basic Usage

**Endpoint:** `POST /speech/transcribe`

```bash
curl -X POST "http://localhost:8000/speech/transcribe" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "audio_base64": "BASE64_AUDIO_DATA",
    "language": "en",
    "translate_to_english": false
  }'
```

**Response:**
```json
{
  "text": "How do I make pasta carbonara?",
  "language": "en",
  "confidence": 0.95
}
```

### Upload Audio File

**Endpoint:** `POST /speech/transcribe/upload`

```bash
curl -X POST "http://localhost:8000/speech/transcribe/upload" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@recording.mp3" \
  -F "language=en" \
  -F "translate_to_english=false"
```

### Features

- **Multi-language Support**: Automatically detect or specify language
- **Translation**: Optional translation to English
- **High Accuracy**: Powered by OpenAI Whisper
- **Format Support**: MP3, WAV, M4A, FLAC, OGG
- **Max File Size**: 25MB

### Language Examples

**English:**
```json
{
  "audio_base64": "...",
  "language": "en"
}
// Output: "Find me a recipe for pasta"
```

**Chinese:**
```json
{
  "audio_base64": "...",
  "language": "zh"
}
// Output: "找意大利面食谱"
```

**Japanese:**
```json
{
  "audio_base64": "...",
  "language": "ja"
}
// Output: "パスタのレシピを探して"
```

---

## 🔊 Text-to-Speech (TTS)

Convert text to natural-sounding speech in any supported language.

### Basic Usage

**Endpoint:** `POST /speech/synthesize`

```bash
curl -X POST "http://localhost:8000/speech/synthesize" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Boil the pasta for 10 minutes",
    "language": "en",
    "slow": false
  }'
```

**Response:**
```json
{
  "audio_base64": "BASE64_MP3_AUDIO",
  "language": "en"
}
```

### Features

- **Natural Voices**: High-quality Google Text-to-Speech
- **Speed Control**: Normal or slow speech
- **Multi-language**: Native pronunciation for all 6 languages
- **MP3 Output**: Standard format for easy playback

### Use Cases

1. **Recipe Narration**: Convert cooking instructions to audio
2. **Nutrition Advice**: Listen to personalized health recommendations
3. **Step-by-Step Guidance**: Audio cooking assistant
4. **Accessibility**: Support for visually impaired users
5. **Multi-language Learning**: Hear pronunciations in different languages

### Language Examples

**English:**
```json
{
  "text": "Add the eggs and cheese to the pasta",
  "language": "en"
}
```

**Thai:**
```json
{
  "text": "เพิ่มไข่และชีสลงในพาสต้า",
  "language": "th"
}
```

**Korean:**
```json
{
  "text": "파스타에 계란과 치즈를 넣으세요",
  "language": "ko"
}
```

---

## 🎙️ Voice Commands

Use voice to control the app with intelligent intent detection.

### Basic Usage

**Endpoint:** `POST /speech/voice-command`

```bash
curl -X POST "http://localhost:8000/speech/voice-command" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "audio_base64": "BASE64_AUDIO",
    "user_language": "en"
  }'
```

**Response:**
```json
{
  "command": "Find recipe for pasta carbonara",
  "language": "en",
  "intent": "search_recipe",
  "parameters": {
    "query": "pasta carbonara"
  },
  "confidence": 0.92
}
```

### Supported Intents

| Intent | Description | Example Commands |
|--------|-------------|------------------|
| `search_recipe` | Find recipes | "Find recipe for pasta", "找意大利面食谱" |
| `create_meal_plan` | Generate meal plans | "Create a 7-day meal plan", "週間の食事プラン" |
| `get_nutrition_info` | Get nutritional info | "How many calories in pasta?", "热量" |
| `analyze_food` | Analyze food | "What is this food?", "これは何?" |
| `get_recommendations` | Get AI suggestions | "Recommend healthy meals", "추천" |
| `add_to_shopping_list` | Add to list | "Add tomatoes to shopping list", "買い物" |
| `log_meal` | Log meal to journal | "Log my breakfast", "기록" |
| `unknown` | Intent not recognized | - |

### Multi-language Voice Commands

**English Examples:**
- "Find recipe for chicken curry"
- "Create a meal plan for this week"
- "How many calories in rice?"
- "Recommend healthy breakfast"

**Chinese Examples:**
- "找鸡肉咖喱食谱" (Find chicken curry recipe)
- "一周饮食计划" (Weekly meal plan)
- "米饭有多少卡路里?" (How many calories in rice?)
- "推荐健康早餐" (Recommend healthy breakfast)

**Japanese Examples:**
- "チキンカレーのレシピを探して" (Find chicken curry recipe)
- "今週の食事プランを作って" (Create this week's meal plan)
- "ご飯のカロリーは?" (How many calories in rice?)
- "健康的な朝食を提案して" (Suggest healthy breakfast)

**Korean Examples:**
- "치킨 카레 레시피 찾아줘" (Find chicken curry recipe)
- "이번 주 식단 만들어줘" (Create this week's meal plan)
- "밥 칼로리 얼마야?" (How many calories in rice?)
- "건강한 아침 추천해줘" (Recommend healthy breakfast)

**Thai Examples:**
- "หาสูตรแกงไก่" (Find chicken curry recipe)
- "สร้างแผนอาหารสัปดาห์นี้" (Create this week's meal plan)
- "ข้าวมีแคลอรีเท่าไร?" (How many calories in rice?)
- "แนะนำอาหารเช้าเพื่อสุขภาพ" (Recommend healthy breakfast)

**Myanmar Examples:**
- "ကြက်သားဟင်းချက်နည်းရှာပါ" (Find chicken curry recipe)
- "ဒီအပတ်စားသောက်မှုစီမံချက်ပြုလုပ်ပါ" (Create this week's meal plan)
- "ထမင်းမှာကယ်လိုရီဘယ်လောက်ရှိသလဲ?" (How many calories in rice?)
- "ကျန်းမာရေးကောင်းမွန်သောနံနက်စာအကြံပြုပါ" (Recommend healthy breakfast)

### Intent Parameters

Each intent extracts relevant parameters:

**search_recipe:**
```json
{
  "intent": "search_recipe",
  "parameters": {
    "query": "pasta carbonara"
  }
}
```

**create_meal_plan:**
```json
{
  "intent": "create_meal_plan",
  "parameters": {
    "days": 7
  }
}
```

**get_nutrition_info:**
```json
{
  "intent": "get_nutrition_info",
  "parameters": {
    "food": "rice"
  }
}
```

---

## 🌐 Translation

Translate text between any supported languages using AI.

### Basic Usage

**Endpoint:** `POST /speech/translate`

```bash
curl -X POST "http://localhost:8000/speech/translate" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "This pasta carbonara is delicious",
    "source_lang": "en",
    "target_lang": "ja"
  }'
```

**Response:**
```json
{
  "translated_text": "このパスタカルボナーラは美味しいです",
  "source_lang": "en",
  "target_lang": "ja"
}
```

### Features

- **LLM-Powered**: High-quality contextual translation
- **Domain-Optimized**: Specialized for food and nutrition
- **Preserves Meaning**: Maintains context and nuance
- **All Language Pairs**: Translate between any 2 of 6 languages

### Translation Examples

**English → Chinese:**
```json
{
  "text": "Add salt and pepper to taste",
  "source_lang": "en",
  "target_lang": "zh"
}
// Result: "加盐和胡椒调味"
```

**Japanese → Korean:**
```json
{
  "text": "この料理は栄養バランスが良いです",
  "source_lang": "ja",
  "target_lang": "ko"
}
// Result: "이 요리는 영양 균형이 좋습니다"
```

**Thai → English:**
```json
{
  "text": "อาหารนี้มีโปรตีนสูง",
  "source_lang": "th",
  "target_lang": "en"
}
// Result: "This food is high in protein"
```

---

## 🔍 Language Detection

Automatically detect the language of text.

### Usage

**Endpoint:** `GET /speech/detect-language`

```bash
curl -X GET "http://localhost:8000/speech/detect-language?text=こんにちは" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Response:**
```json
{
  "detected_language": "ja",
  "language_name": "Japanese",
  "text": "こんにちは"
}
```

### Features

- **Auto-Detection**: Identify language from text
- **High Accuracy**: Powered by langdetect library
- **Fallback**: Defaults to English if uncertain

---

## 📱 Integration Examples

### Web/Mobile App Integration

**1. Voice Command Flow:**
```javascript
// Record audio
const audioBlob = await recordAudio();
const audioBase64 = await blobToBase64(audioBlob);

// Send to API
const response = await fetch('/speech/voice-command', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    audio_base64: audioBase64,
    user_language: 'en'
  })
});

const result = await response.json();

// Handle intent
switch(result.intent) {
  case 'search_recipe':
    searchRecipe(result.parameters.query);
    break;
  case 'create_meal_plan':
    createMealPlan(result.parameters.days);
    break;
  // ... handle other intents
}
```

**2. Text-to-Speech for Recipe Instructions:**
```javascript
// Get recipe instructions
const recipe = await getRecipe(recipeId);

// Convert to speech
const response = await fetch('/speech/synthesize', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    text: recipe.instructions.join('. '),
    language: userLanguage,
    slow: false
  })
});

const result = await response.json();
const audioBlob = base64ToBlob(result.audio_base64, 'audio/mp3');
const audioUrl = URL.createObjectURL(audioBlob);

// Play audio
const audio = new Audio(audioUrl);
audio.play();
```

**3. Multi-language Recipe Search:**
```javascript
// User searches in their native language
const userQuery = "パスタのレシピ"; // Japanese

// Detect language
const langResponse = await fetch(`/speech/detect-language?text=${userQuery}`, {
  headers: { 'Authorization': `Bearer ${token}` }
});
const { detected_language } = await langResponse.json();

// Translate to English for search
const translateResponse = await fetch('/speech/translate', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    text: userQuery,
    source_lang: detected_language,
    target_lang: 'en'
  })
});

const { translated_text } = await translateResponse.json();

// Search with translated query
const recipes = await searchRecipes(translated_text);
```

---

## 🎯 Best Practices

### Speech-to-Text
- Use appropriate audio formats (MP3, WAV recommended)
- Ensure clear audio quality for better accuracy
- Specify language when known (improves accuracy)
- Keep files under 25MB for optimal performance

### Text-to-Speech
- Break long text into smaller chunks for better pacing
- Use `slow: true` for step-by-step instructions
- Cache generated audio to reduce API calls
- Match language to user preference

### Voice Commands
- Provide visual feedback during recording
- Show transcribed text for confirmation
- Handle `unknown` intent gracefully
- Support both voice and text input

### Translation
- Cache translations to reduce API calls
- Validate language codes before submission
- Handle translation errors gracefully
- Show original text alongside translation

### Language Selection
- Auto-detect from user profile
- Allow manual override
- Save preference for future sessions
- Provide language picker UI

---

## 🚀 Advanced Features

### Hands-free Cooking Mode

Create a voice-controlled cooking experience:

1. **Start Recipe**: "Start recipe for pasta carbonara"
2. **Navigate Steps**: "Next step", "Previous step", "Repeat step"
3. **Set Timers**: "Set timer for 10 minutes"
4. **Ask Questions**: "How do I know when pasta is done?"
5. **Add to Shopping**: "Add parmesan cheese to shopping list"

### Multi-language Meal Planning

Generate meal plans with multi-language support:

1. User sets preferred language in profile
2. AI generates meal plan
3. All recipes translated to user's language
4. Voice instructions in native language
5. Shopping list in local language

### Cross-cultural Recipe Discovery

Find similar dishes across cultures:

1. User describes a dish in their language
2. System translates and finds similar dishes
3. Results include recipes from multiple cuisines
4. Each recipe available in user's language

---

## 🛠️ Technical Details

### Audio Processing
- **STT Engine**: OpenAI Whisper (multilingual model)
- **TTS Engine**: Google Text-to-Speech (gTTS)
- **Audio Format**: MP3 output, multiple input formats
- **Encoding**: Base64 for API transfer

### Language Detection
- **Library**: langdetect
- **Method**: Statistical analysis
- **Fallback**: English (en)

### Translation
- **Engine**: LLaMA 3.2 via Ollama
- **Method**: Context-aware AI translation
- **Temperature**: 0.3 (balanced quality)
- **Max Tokens**: 500

### Intent Detection
- **Method**: Pattern matching + keyword analysis
- **Languages**: All 6 supported languages
- **Confidence**: Based on match strength

---

## 📊 Supported Language Codes

Quick reference for API calls:

```json
{
  "en": "English",
  "zh": "Chinese/Mandarin",
  "ja": "Japanese",
  "ko": "Korean",
  "th": "Thai",
  "my": "Myanmar/Burmese"
}
```

---

## 🆘 Troubleshooting

### Common Issues

**1. Low transcription accuracy:**
- Check audio quality (clear recording, minimal background noise)
- Specify correct language code
- Ensure proper audio format
- Try translating to English for better results

**2. TTS audio quality:**
- gTTS provides natural voices but may vary by language
- Use `slow: true` for clearer pronunciation
- Break long text into sentences

**3. Intent not detected:**
- Use clear, direct commands
- Include keywords from intent patterns
- Check language matches user_language parameter
- Review supported intents list

**4. Translation errors:**
- Verify language codes are correct
- Ensure text is not empty
- Check for special characters
- Try shorter text segments

---

## 📖 Resources

- **API Documentation**: `/docs`
- **Interactive Testing**: `/docs` (Swagger UI)
- **Full Endpoint Reference**: `API_ENDPOINTS.md`
- **Authentication Guide**: `AUTH_GUIDE.md`

---

**NutriVision AI** - Voice-enabled, multilingual nutrition assistant powered by AI
