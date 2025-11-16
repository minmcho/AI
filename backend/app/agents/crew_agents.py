from crewai import Agent, Task, Crew, Process
from langchain.llms import Ollama
from typing import List, Dict
from app.config.settings import get_settings

settings = get_settings()


class NutritionCrewAgents:
    """CrewAI multi-agent system for meal planning and nutrition"""

    def __init__(self):
        # Initialize LLM for agents
        self.llm = Ollama(
            model="llama3.2",
            base_url=settings.OLLAMA_BASE_URL
        )

    def create_meal_planner_agent(self) -> Agent:
        """Agent responsible for creating meal plans"""
        return Agent(
            role="Meal Planning Expert",
            goal="Create personalized, balanced meal plans that meet nutritional goals",
            backstory="""You are an experienced nutritionist and meal planning expert.
            You understand how to balance macronutrients, accommodate dietary restrictions,
            and create diverse, enjoyable meal plans.""",
            verbose=True,
            allow_delegation=True,
            llm=self.llm
        )

    def create_nutrition_advisor_agent(self) -> Agent:
        """Agent for nutrition analysis and recommendations"""
        return Agent(
            role="Nutrition Advisor",
            goal="Analyze nutritional content and provide health recommendations",
            backstory="""You are a certified nutritionist with deep knowledge of
            macronutrients, micronutrients, and their impact on health.""",
            verbose=True,
            allow_delegation=False,
            llm=self.llm
        )

    def create_recipe_discovery_agent(self) -> Agent:
        """Agent for finding and suggesting recipes"""
        return Agent(
            role="Recipe Discovery Specialist",
            goal="Find and recommend recipes based on preferences and constraints",
            backstory="""You are a culinary researcher with extensive knowledge of
            international cuisines, cooking techniques, and recipe databases.""",
            verbose=True,
            allow_delegation=True,
            llm=self.llm
        )

    def create_shopping_assistant_agent(self) -> Agent:
        """Agent for shopping list generation and optimization"""
        return Agent(
            role="Shopping Assistant",
            goal="Create efficient shopping lists and find best deals",
            backstory="""You are an expert at optimizing grocery shopping,
            finding substitutes, and managing food budgets.""",
            verbose=True,
            allow_delegation=False,
            llm=self.llm
        )

    def create_cooking_coach_agent(self) -> Agent:
        """Agent for cooking guidance and support"""
        return Agent(
            role="Cooking Coach",
            goal="Provide step-by-step cooking guidance and troubleshooting",
            backstory="""You are a professional chef and cooking instructor
            with expertise in teaching cooking techniques and problem-solving.""",
            verbose=True,
            allow_delegation=False,
            llm=self.llm
        )

    def create_cultural_cuisine_agent(self) -> Agent:
        """Agent for cross-cultural meal analysis"""
        return Agent(
            role="Cultural Cuisine Expert",
            goal="Analyze and compare meals across different cultures",
            backstory="""You are a food anthropologist with deep knowledge of
            cuisines from around the world, their histories, and similarities.""",
            verbose=True,
            allow_delegation=False,
            llm=self.llm
        )

    def create_beverage_sommelier_agent(self) -> Agent:
        """Agent for beverage pairing recommendations"""
        return Agent(
            role="Beverage Sommelier",
            goal="Recommend perfect beverage pairings for meals",
            backstory="""You are a certified sommelier and beverage expert
            with knowledge of wine, beer, cocktails, and non-alcoholic pairings.""",
            verbose=True,
            allow_delegation=False,
            llm=self.llm
        )

    async def generate_weekly_meal_plan(
        self,
        user_profile: Dict,
        days: int = 7
    ) -> Dict:
        """Generate a weekly meal plan using multiple agents"""

        # Create agents
        planner = self.create_meal_planner_agent()
        nutrition = self.create_nutrition_advisor_agent()
        recipe_finder = self.create_recipe_discovery_agent()

        # Create tasks
        analyze_needs = Task(
            description=f"""Analyze the user's nutritional needs and preferences:
            - Dietary restrictions: {user_profile.get('dietary_restrictions', [])}
            - Daily calorie target: {user_profile.get('daily_calories', 2000)}
            - Health goals: {user_profile.get('health_goals', [])}
            - Allergies: {user_profile.get('allergies', [])}

            Provide a summary of nutritional requirements.""",
            agent=nutrition,
            expected_output="Nutritional requirements summary"
        )

        find_recipes = Task(
            description=f"""Find suitable recipes for a {days}-day meal plan that:
            - Match the dietary restrictions: {user_profile.get('dietary_restrictions', [])}
            - Fit within the calorie budget: {user_profile.get('daily_calories', 2000)}
            - Include preferred cuisines: {user_profile.get('cuisine_preferences', [])}
            - Avoid allergies: {user_profile.get('allergies', [])}

            Suggest breakfast, lunch, dinner, and snacks for each day.""",
            agent=recipe_finder,
            expected_output="Recipe suggestions for the meal plan"
        )

        create_plan = Task(
            description=f"""Create a balanced {days}-day meal plan that:
            - Meets the nutritional requirements
            - Uses the suggested recipes
            - Provides variety across days
            - Balances flavors and cooking complexity

            Format as a detailed day-by-day plan.""",
            agent=planner,
            expected_output="Complete meal plan"
        )

        # Create crew
        crew = Crew(
            agents=[nutrition, recipe_finder, planner],
            tasks=[analyze_needs, find_recipes, create_plan],
            process=Process.sequential,
            verbose=True
        )

        # Execute
        result = crew.kickoff()

        return {
            "meal_plan": str(result),
            "generated_by": "CrewAI Multi-Agent System",
            "agents_used": ["Nutrition Advisor", "Recipe Discovery", "Meal Planner"]
        }

    async def analyze_cross_cultural_similarity(
        self,
        meal_description: str,
        target_cuisines: List[str]
    ) -> Dict:
        """Analyze meal similarity across cultures"""

        cultural_agent = self.create_cultural_cuisine_agent()

        task = Task(
            description=f"""Analyze this meal: "{meal_description}"

            Find similar dishes in these cuisines: {', '.join(target_cuisines)}

            For each similar dish, explain:
            - The name and origin
            - Key similarities in ingredients or preparation
            - Cultural significance
            - Notable differences

            Provide at least 3 matches.""",
            agent=cultural_agent,
            expected_output="Cross-cultural meal analysis"
        )

        crew = Crew(
            agents=[cultural_agent],
            tasks=[task],
            process=Process.sequential,
            verbose=True
        )

        result = crew.kickoff()

        return {
            "analysis": str(result),
            "agent": "Cultural Cuisine Expert"
        }

    async def suggest_beverage_pairing(
        self,
        meal_description: str,
        preferences: Dict
    ) -> Dict:
        """Get beverage pairing suggestions"""

        sommelier = self.create_beverage_sommelier_agent()

        task = Task(
            description=f"""Suggest beverage pairings for this meal: "{meal_description}"

            Consider:
            - Alcohol preference: {preferences.get('alcohol', 'any')}
            - Flavor profile preferences: {preferences.get('flavors', [])}
            - Budget: {preferences.get('budget', 'moderate')}

            Suggest 3 different beverages with explanations for why they pair well.""",
            agent=sommelier,
            expected_output="Beverage pairing recommendations"
        )

        crew = Crew(
            agents=[sommelier],
            tasks=[task],
            process=Process.sequential,
            verbose=True
        )

        result = crew.kickoff()

        return {
            "pairings": str(result),
            "agent": "Beverage Sommelier"
        }


# Singleton instance
crew_agents = NutritionCrewAgents()
