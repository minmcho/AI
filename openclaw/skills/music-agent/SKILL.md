# VideoFeed Music Agent

## Metadata
- **skill**: videofeed-music
- **version**: 1.0.0
- **author**: videofeed
- **description**: Generates AI background music for videos using the ace-music skill (ACE-Step 1.5).
- **dependencies**: ace-music

## Overview
This skill generates a background mix track for a video feed post using OpenClaw's
`ace-music` skill powered by ACE-Step 1.5 via ACE Music's free API.

The agent crafts a genre- and mood-aware prompt and submits it to ace-music,
then returns the audio URL for storage in Supabase and playback in the iOS app's AutoMix feature.

## Instructions

You will receive a context object with:
- `genre`: Music genre (electronic, hiphop, lofi, pop, ambient, edm)
- `mood`: Emotional mood (energetic, chill, dramatic, uplifting, dark)
- `duration`: Target duration in seconds (default: 30)

### Steps

1. Construct a descriptive music prompt:
   > "Generate a {{duration}}-second {{genre}} instrumental track with a {{mood}} mood.
   > No vocals. Suitable for a short-form video background. High production quality."

2. Call the `ace-music` skill:
   ```json
   {
     "prompt": "{{constructed_prompt}}",
     "duration": {{duration}},
     "genre": "{{genre}}",
     "tags": ["instrumental", "background", "{{mood}}"]
   }
   ```

3. Wait for completion (poll every 3 seconds, max 5 minutes).

4. Return:
   ```json
   { "output": { "audio_url": "<generated_audio_url>" } }
   ```

5. Optionally submit to claw.fm for the shared royalty pool:
   - Only if the user has opted in to `publish_to_clawfm: true` in context.

## Example Prompts
- "Create an energetic EDM track for a dance video"
- "Generate a chill lo-fi beat for a lifestyle video"
- "Make a dramatic cinematic score for a travel montage"
