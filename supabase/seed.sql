-- Sample profiles
INSERT INTO profiles (id, username, avatar_url, bio) VALUES
  ('00000000-0000-0000-0000-000000000001', 'demo_user',   'https://i.pravatar.cc/150?u=demo',   'VideoFeed demo account'),
  ('00000000-0000-0000-0000-000000000002', 'travel_benny', 'https://i.pravatar.cc/150?u=benny', 'Travel content creator')
ON CONFLICT DO NOTHING;

-- Sample videos (point at public Supabase storage or CDN URLs in production)
INSERT INTO videos (id, profile_id, url, thumbnail, caption, likes, comments, shares, duration, tags) VALUES
  (
    '10000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'https://peach.blender.org/wp-content/uploads/bbb-splash.png',
    'Big Buck Bunny — open-source animation classic #animation #fun',
    1204, 88, 42, 596,
    '{animation, fun, classic}'
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000002',
    'https://storage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Elephants_Dream_s5_both.jpg/320px-Elephants_Dream_s5_both.jpg',
    'Elephants Dream — surreal sci-fi short #scifi #art',
    876, 53, 31, 654,
    '{scifi, art, animation}'
  )
ON CONFLICT DO NOTHING;

-- Default preferences for demo user
INSERT INTO user_preferences (profile_id, music_genres, music_moods, video_types, countries, platforms) VALUES
  (
    '00000000-0000-0000-0000-000000000001',
    '{electronic, lofi}',
    '{energetic, chill}',
    '{animation, art, travel}',
    '{US, JP, KR, BR}',
    '{youtube, tiktok, spotify}'
  )
ON CONFLICT (profile_id) DO NOTHING;
