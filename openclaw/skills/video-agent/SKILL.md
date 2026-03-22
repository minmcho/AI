# VideoFeed Video Agent

## Metadata
- **skill**: videofeed-video-edit
- **version**: 1.0.0
- **author**: videofeed
- **description**: Edits short-form videos with AI dubbing, lip-sync, and subtitle overlay using eachlabs-video-edit.
- **dependencies**: eachlabs-video-edit

## Overview
This skill receives a video URL, a dubbed audio URL, and a target language.
It submits a job to the eachlabs-video-edit API to:
1. Replace original audio with the dubbed track
2. Apply lip-sync to match the new audio
3. Burn subtitles into the video in the target language

## Instructions

When triggered, you will receive a context object with:
- `video_url`: Source video URL (Supabase Storage)
- `audio_url`: TTS-generated dubbed audio URL
- `subtitle_language`: ISO 639-1 language code (e.g., "es", "ja")
- `lip_sync`: boolean — whether to apply lip-sync

### Steps

1. Call the `eachlabs-video-edit` skill with:
   ```json
   {
     "source_video": "{{video_url}}",
     "replace_audio": "{{audio_url}}",
     "lip_sync": {{lip_sync}},
     "subtitles": {
       "enabled": true,
       "language": "{{subtitle_language}}",
       "style": "tiktok"
     }
   }
   ```

2. Wait for the job to complete (poll every 3 seconds).

3. Return the output video URL in:
   ```json
   { "output": { "video_url": "<processed_video_url>" } }
   ```

4. On failure, return:
   ```json
   { "status": "failed", "error": "<reason>" }
   ```

## Example Prompt
"Apply Spanish dubbing to this video and add Spanish subtitles with lip sync."
