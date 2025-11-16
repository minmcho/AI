import requests
from typing import List, Dict, Optional
from app.config.settings import get_settings

settings = get_settings()


class LLMService:
    """Service for LLaMA 3.2 integration via Ollama"""

    def __init__(self):
        self.base_url = settings.OLLAMA_BASE_URL
        self.model = "llama3.2"

    async def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: int = 500
    ) -> str:
        """Generate text using LLaMA 3.2"""
        try:
            messages = []
            if system_prompt:
                messages.append({"role": "system", "content": system_prompt})
            messages.append({"role": "user", "content": prompt})

            response = requests.post(
                f"{self.base_url}/api/chat",
                json={
                    "model": self.model,
                    "messages": messages,
                    "stream": False,
                    "options": {
                        "temperature": temperature,
                        "num_predict": max_tokens,
                    }
                }
            )

            if response.status_code == 200:
                return response.json()["message"]["content"]
            else:
                return f"Error: {response.status_code}"

        except Exception as e:
            return f"Error generating response: {str(e)}"

    async def chat_cooking_assistant(self, message: str, context: Dict) -> Dict:
        """Chat with cooking assistant"""
        system_prompt = """You are an expert cooking assistant with deep knowledge of:
        - Culinary techniques and cooking methods
        - Recipe modifications and substitutions
        - Timing and temperature guidelines
        - Troubleshooting common cooking issues
        - Food safety and storage

        Provide helpful, clear, and actionable advice."""

        user_context = f"""
        User dietary restrictions: {context.get('dietary_restrictions', [])}
        Cooking experience: {context.get('experience_level', 'intermediate')}
        Current recipe: {context.get('current_recipe', 'None')}

        Question: {message}
        """

        response = await self.generate(
            prompt=user_context,
            system_prompt=system_prompt,
            temperature=0.7
        )

        return {
            "message": response,
            "agent_name": "Cooking Assistant",
            "suggestions": [],
            "confidence": 0.9
        }

    async def generate_meal_plan_suggestions(
        self,
        user_profile: Dict,
        days: int = 7
    ) -> List[Dict]:
        """Generate meal plan suggestions using LLaMA"""
        system_prompt = """You are a professional nutritionist and meal planning expert.
        Create balanced, diverse meal plans that consider dietary restrictions,
        nutritional goals, and user preferences."""

        prompt = f"""
        Create a {days}-day meal plan for:
        - Dietary restrictions: {user_profile.get('dietary_restrictions', [])}
        - Calorie target: {user_profile.get('daily_calories', 2000)} per day
        - Cuisine preferences: {user_profile.get('cuisine_preferences', [])}
        - Allergies: {user_profile.get('allergies', [])}

        Format as JSON with breakfast, lunch, dinner, and snacks for each day.
        """

        response = await self.generate(
            prompt=prompt,
            system_prompt=system_prompt,
            temperature=0.8,
            max_tokens=1500
        )

        return {"plan": response}

    async def explain_recipe_technique(self, technique: str) -> str:
        """Explain a cooking technique"""
        system_prompt = "You are a culinary instructor explaining cooking techniques clearly and concisely."

        prompt = f"Explain the cooking technique: {technique}. Include tips for success."

        return await self.generate(
            prompt=prompt,
            system_prompt=system_prompt,
            temperature=0.6
        )

    async def suggest_wine_pairing(
        self,
        meal_description: str,
        preferences: Dict
    ) -> Dict:
        """Suggest wine or beverage pairing"""
        system_prompt = """You are a sommelier and beverage expert.
        Suggest appropriate drink pairings considering flavor profiles,
        regional traditions, and user preferences."""

        prompt = f"""
        Meal: {meal_description}
        Preferences: {preferences}

        Suggest 3 beverage pairings (wine, beer, or non-alcoholic).
        For each, explain why it pairs well.
        """

        response = await self.generate(
            prompt=prompt,
            system_prompt=system_prompt,
            temperature=0.7
        )

        return {"pairings": response}


# Singleton instance
llm_service = LLMService()
