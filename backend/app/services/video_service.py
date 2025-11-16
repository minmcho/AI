from typing import List, Dict, Optional
import httpx
from googleapiclient.discovery import build
from app.config.settings import get_settings
from app.services.embedding_service import embedding_service

settings = get_settings()


class VideoRecommendationService:
    """Service for discovering cooking videos from YouTube and social media"""

    def __init__(self):
        self.youtube_api_key = settings.YOUTUBE_API_KEY
        self.youtube = None

    def _init_youtube(self):
        """Initialize YouTube API client"""
        if self.youtube is None and self.youtube_api_key:
            self.youtube = build('youtube', 'v3', developerKey=self.youtube_api_key)

    async def search_youtube_videos(
        self,
        query: str,
        max_results: int = 10
    ) -> List[Dict]:
        """Search YouTube for cooking videos"""

        if not self.youtube_api_key:
            print("Warning: YouTube API key not configured")
            return []

        self._init_youtube()

        try:
            # Search for videos
            search_response = self.youtube.search().list(
                q=query,
                part='id,snippet',
                maxResults=max_results,
                type='video',
                videoCategoryId='26',  # Howto & Style category
                relevanceLanguage='en',
                safeSearch='strict'
            ).execute()

            videos = []
            for item in search_response.get('items', []):
                video_id = item['id']['videoId']

                # Get video statistics
                stats_response = self.youtube.videos().list(
                    part='statistics,contentDetails',
                    id=video_id
                ).execute()

                stats = stats_response['items'][0] if stats_response['items'] else {}

                video_data = {
                    "platform": "youtube",
                    "video_id": video_id,
                    "title": item['snippet']['title'],
                    "description": item['snippet']['description'],
                    "url": f"https://www.youtube.com/watch?v={video_id}",
                    "thumbnail_url": item['snippet']['thumbnails']['high']['url'],
                    "channel_name": item['snippet']['channelTitle'],
                    "channel_url": f"https://www.youtube.com/channel/{item['snippet']['channelId']}",
                    "published_at": item['snippet']['publishedAt'],
                    "view_count": int(stats.get('statistics', {}).get('viewCount', 0)),
                    "like_count": int(stats.get('statistics', {}).get('likeCount', 0)),
                    "duration": stats.get('contentDetails', {}).get('duration', 'PT0S'),
                }

                videos.append(video_data)

            return videos

        except Exception as e:
            print(f"Error searching YouTube: {e}")
            return []

    async def find_recipe_videos(
        self,
        recipe_name: str,
        cuisine: str = None,
        max_results: int = 5
    ) -> List[Dict]:
        """Find videos for a specific recipe"""

        # Build search query
        query_parts = [recipe_name, "recipe", "cooking"]
        if cuisine:
            query_parts.append(cuisine)

        query = " ".join(query_parts)

        videos = await self.search_youtube_videos(query, max_results)

        # Rank videos by relevance using embeddings
        if videos:
            videos_with_scores = await self._rank_videos_by_relevance(
                recipe_name,
                videos
            )
            return videos_with_scores

        return videos

    async def _rank_videos_by_relevance(
        self,
        recipe_name: str,
        videos: List[Dict]
    ) -> List[Dict]:
        """Rank videos using semantic similarity"""

        # Get recipe name embedding
        recipe_embedding = await embedding_service.encode_text(recipe_name)

        # Score each video
        for video in videos:
            # Combine title and description for matching
            video_text = f"{video['title']} {video['description']}"
            video_embedding = await embedding_service.encode_text(video_text)

            # Calculate similarity
            similarity = await embedding_service.calculate_similarity(
                recipe_embedding,
                video_embedding
            )

            video['relevance_score'] = similarity

            # Boost score based on engagement
            engagement_boost = min(video['view_count'] / 1000000, 0.2)  # Max 0.2 boost
            video['relevance_score'] += engagement_boost

        # Sort by relevance score
        videos.sort(key=lambda x: x['relevance_score'], reverse=True)

        return videos

    async def search_tiktok_videos(
        self,
        recipe_name: str,
        max_results: int = 5
    ) -> List[Dict]:
        """Search TikTok for recipe videos (requires TikTok API access)"""

        # Note: TikTok API requires special access
        # For now, return placeholder data structure

        # In production, integrate with:
        # - TikTok Developer API
        # - Web scraping (with proper rate limiting and ToS compliance)

        return []

    async def search_instagram_reels(
        self,
        recipe_name: str,
        max_results: int = 5
    ) -> List[Dict]:
        """Search Instagram for recipe reels"""

        # Note: Instagram Graph API has limitations
        # Requires business account and proper permissions

        # In production, integrate with:
        # - Instagram Graph API
        # - Hashtag searches
        # - Content creator partnerships

        return []

    async def get_trending_cooking_videos(
        self,
        cuisine: Optional[str] = None,
        limit: int = 10
    ) -> List[Dict]:
        """Get trending cooking videos"""

        query = "trending cooking recipes"
        if cuisine:
            query = f"trending {cuisine} recipes"

        videos = await self.search_youtube_videos(query, limit)

        # Filter for recent videos (last 30 days)
        from datetime import datetime, timedelta
        recent_date = datetime.now() - timedelta(days=30)

        recent_videos = [
            v for v in videos
            if datetime.fromisoformat(v['published_at'].replace('Z', '+00:00')) > recent_date
        ]

        return recent_videos

    async def get_cooking_technique_videos(
        self,
        technique: str,
        max_results: int = 3
    ) -> List[Dict]:
        """Find tutorial videos for specific cooking techniques"""

        query = f"how to {technique} cooking tutorial"
        videos = await self.search_youtube_videos(query, max_results)

        # Filter for tutorial-style videos (typically longer, educational)
        tutorial_videos = [
            v for v in videos
            if any(keyword in v['title'].lower() for keyword in ['how to', 'tutorial', 'guide', 'learn'])
        ]

        return tutorial_videos

    async def aggregate_multi_platform_videos(
        self,
        recipe_name: str,
        max_per_platform: int = 3
    ) -> Dict[str, List[Dict]]:
        """Aggregate videos from multiple platforms"""

        results = {
            "youtube": await self.find_recipe_videos(recipe_name, max_results=max_per_platform),
            "tiktok": await self.search_tiktok_videos(recipe_name, max_results=max_per_platform),
            "instagram": await self.search_instagram_reels(recipe_name, max_results=max_per_platform),
        }

        return results

    def parse_duration(self, duration_str: str) -> int:
        """Parse ISO 8601 duration to seconds"""
        import re

        # Parse PT#H#M#S format
        pattern = r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?'
        match = re.match(pattern, duration_str)

        if not match:
            return 0

        hours = int(match.group(1) or 0)
        minutes = int(match.group(2) or 0)
        seconds = int(match.group(3) or 0)

        return hours * 3600 + minutes * 60 + seconds


# Singleton instance
video_service = VideoRecommendationService()
