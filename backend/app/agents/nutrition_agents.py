from crewai import Agent, Task, Crew, Process
from langchain.llms import Ollama
from typing import Dict, List
from app.config.settings import get_settings
from app.models.user import User

settings = get_settings()


class SmartNutritionPlanner:
    """
    Smart nutrition planning system that creates personalized diet plans
    based on user's health profile, allergies, and goals
    """

    def __init__(self):
        self.llm = Ollama(
            model="llama3.2",
            base_url=settings.OLLAMA_BASE_URL
        )

    def create_personalized_nutrition_advisor(self, user: User) -> Agent:
        """Create personalized nutrition advisor based on user profile"""

        # Build context from user profile
        user_context = f"""
        User Profile:
        - Age: {user.age} years
        - Sex: {user.sex.value if user.sex else 'not specified'}
        - Weight: {user.weight_kg} kg
        - Height: {user.height_cm} cm
        - Activity Level: {user.activity_level.value if user.activity_level else 'moderate'}
        - Daily Calorie Target: {user.target_calories} kcal

        Dietary Restrictions: {', '.join(user.dietary_restrictions) if user.dietary_restrictions else 'None'}
        Allergies: {', '.join(user.allergies) if user.allergies else 'None'}
        Health Goals: {', '.join(user.health_goals) if user.health_goals else 'general wellness'}
        Medical Conditions: {', '.join(user.medical_conditions) if user.medical_conditions else 'None'}
        """

        return Agent(
            role="Personalized Nutrition Advisor",
            goal=f"Create optimal nutrition and meal plans for this specific user",
            backstory=f"""You are a certified nutritionist and dietitian specializing in
            personalized nutrition planning. You have access to this user's complete health profile:

            {user_context}

            You must:
            - Always respect their allergies and dietary restrictions
            - Align recommendations with their health goals
            - Consider their medical conditions when making suggestions
            - Ensure nutritional adequacy and balance
            - Provide science-based recommendations""",
            verbose=True,
            allow_delegation=False,
            llm=self.llm
        )

    def create_macro_calculator_agent(self) -> Agent:
        """Agent for calculating optimal macronutrient ratios"""
        return Agent(
            role="Macronutrient Calculator",
            goal="Calculate optimal protein, carbs, and fat ratios based on user goals",
            backstory="""You are an expert in sports nutrition and metabolism.
            You calculate precise macronutrient distributions based on:
            - User's health goals (weight loss, muscle gain, etc.)
            - Activity level and lifestyle
            - Medical conditions (diabetes, heart disease, etc.)
            - Dietary preferences and restrictions

            You use evidence-based formulas and adjust for individual needs.""",
            verbose=True,
            allow_delegation=False,
            llm=self.llm
        )

    def create_allergy_safety_agent(self) -> Agent:
        """Agent to ensure meal plans are safe for user's allergies"""
        return Agent(
            role="Allergy Safety Specialist",
            goal="Verify all meal recommendations are safe and free from allergens",
            backstory="""You are a food allergy specialist with expertise in:
            - Identifying hidden allergens in foods
            - Cross-contamination risks
            - Safe substitutions for allergenic ingredients
            - Reading ingredient labels

            You NEVER compromise on safety and always double-check for allergens.""",
            verbose=True,
            allow_delegation=False,
            llm=self.llm
        )

    async def generate_personalized_meal_plan(
        self,
        user: User,
        days: int = 7,
        preferences: Dict = None
    ) -> Dict:
        """Generate a personalized meal plan using smart agents"""

        # Create specialized agents
        nutrition_advisor = self.create_personalized_nutrition_advisor(user)
        macro_calculator = self.create_macro_calculator_agent()
        allergy_specialist = self.create_allergy_safety_agent()

        # Calculate BMI for context
        bmi = None
        if user.weight_kg and user.height_cm:
            height_m = user.height_cm / 100
            bmi = user.weight_kg / (height_m ** 2)

        # Build user summary
        user_summary = f"""
        Age: {user.age}, Sex: {user.sex.value if user.sex else 'not specified'}
        Weight: {user.weight_kg} kg, Height: {user.height_cm} cm
        BMI: {bmi:.1f if bmi else 'N/A'}
        Daily Calories: {user.target_calories} kcal
        Activity: {user.activity_level.value if user.activity_level else 'moderate'}
        Goals: {', '.join(user.health_goals) if user.health_goals else 'general wellness'}
        Restrictions: {', '.join(user.dietary_restrictions) if user.dietary_restrictions else 'None'}
        ALLERGIES: {', '.join(user.allergies) if user.allergies else 'None'}
        """

        # Task 1: Calculate optimal macros
        calculate_macros_task = Task(
            description=f"""Calculate optimal macronutrient distribution for:
            {user_summary}

            Provide:
            1. Daily protein target (grams)
            2. Daily carbohydrate target (grams)
            3. Daily fat target (grams)
            4. Rationale for these recommendations

            Consider their health goals and activity level.""",
            agent=macro_calculator,
            expected_output="Macronutrient targets with rationale"
        )

        # Task 2: Create meal plan
        create_plan_task = Task(
            description=f"""Create a {days}-day personalized meal plan for:
            {user_summary}

            Requirements:
            - Meet the calculated macro targets
            - Respect ALL dietary restrictions
            - AVOID all allergens completely
            - Provide variety across days
            - Include breakfast, lunch, dinner, and 1-2 snacks daily
            - Ensure nutritional completeness

            Format each day with:
            - Meal times
            - Food items and portions
            - Approximate calories per meal
            - Total daily macros""",
            agent=nutrition_advisor,
            expected_output="Complete meal plan"
        )

        # Task 3: Safety verification
        verify_safety_task = Task(
            description=f"""Review the meal plan and verify it is safe for:

            ALLERGIES TO AVOID: {', '.join(user.allergies) if user.allergies else 'None'}

            Check EVERY ingredient in EVERY meal for:
            1. Direct presence of allergens
            2. Cross-contamination risks
            3. Hidden allergens (derivatives, additives)

            If ANY allergen is found, FLAG IT IMMEDIATELY and suggest safe alternatives.

            Provide a safety report confirming the plan is allergen-free.""",
            agent=allergy_specialist,
            expected_output="Safety verification report"
        )

        # Create crew and execute
        crew = Crew(
            agents=[macro_calculator, nutrition_advisor, allergy_specialist],
            tasks=[calculate_macros_task, create_plan_task, verify_safety_task],
            process=Process.sequential,
            verbose=True
        )

        result = crew.kickoff()

        return {
            "user_id": user.id,
            "days": days,
            "meal_plan": str(result),
            "user_profile": {
                "age": user.age,
                "weight_kg": user.weight_kg,
                "height_cm": user.height_cm,
                "bmi": round(bmi, 1) if bmi else None,
                "target_calories": user.target_calories,
                "allergies": user.allergies,
                "dietary_restrictions": user.dietary_restrictions,
                "health_goals": user.health_goals,
            },
            "generated_by": "Smart Multi-Agent Nutrition System",
            "agents_used": [
                "Macronutrient Calculator",
                "Personalized Nutrition Advisor",
                "Allergy Safety Specialist"
            ]
        }

    async def get_personalized_recommendations(self, user: User) -> Dict:
        """Get personalized nutrition recommendations based on user profile"""

        advisor = self.create_personalized_nutrition_advisor(user)

        # Calculate current BMI and status
        bmi = None
        bmi_category = None
        if user.weight_kg and user.height_cm:
            height_m = user.height_cm / 100
            bmi = user.weight_kg / (height_m ** 2)

            if bmi < 18.5:
                bmi_category = "underweight"
            elif bmi < 25:
                bmi_category = "normal weight"
            elif bmi < 30:
                bmi_category = "overweight"
            else:
                bmi_category = "obese"

        task = Task(
            description=f"""Provide personalized nutrition recommendations for:

            Profile:
            - Age: {user.age}, Sex: {user.sex.value if user.sex else 'not specified'}
            - Current Weight: {user.weight_kg} kg, Height: {user.height_cm} cm
            - BMI: {bmi:.1f if bmi else 'N/A'} ({bmi_category})
            - Health Goals: {', '.join(user.health_goals) if user.health_goals else 'general wellness'}
            - Activity Level: {user.activity_level.value if user.activity_level else 'moderate'}
            - Dietary Restrictions: {', '.join(user.dietary_restrictions) if user.dietary_restrictions else 'None'}
            - Allergies: {', '.join(user.allergies) if user.allergies else 'None'}
            - Medical Conditions: {', '.join(user.medical_conditions) if user.medical_conditions else 'None'}

            Provide:
            1. Current nutrition assessment
            2. Specific recommendations for their health goals
            3. Foods to emphasize
            4. Foods to limit/avoid (beyond allergies)
            5. Supplement recommendations if needed
            6. Lifestyle tips for achieving goals
            7. Timeline and expectations

            Be specific, actionable, and evidence-based.""",
            agent=advisor,
            expected_output="Personalized nutrition recommendations"
        )

        crew = Crew(
            agents=[advisor],
            tasks=[task],
            process=Process.sequential,
            verbose=True
        )

        result = crew.kickoff()

        return {
            "user_id": user.id,
            "recommendations": str(result),
            "bmi": round(bmi, 1) if bmi else None,
            "bmi_category": bmi_category,
            "generated_by": "Personalized Nutrition Advisor"
        }


# Singleton instance
nutrition_planner = SmartNutritionPlanner()
