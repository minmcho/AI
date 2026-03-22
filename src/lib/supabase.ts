import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string;

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  realtime: {
    params: { eventsPerSecond: 10 },
  },
});

// Fetch paginated video feed
export async function fetchVideoFeed(page = 0, limit = 5): Promise<import('../types').Video[]> {
  const { data, error } = await supabase
    .from('videos')
    .select(`
      id, url, thumbnail, caption, likes, comments, shares,
      duration, tags, mix_track_url, created_at,
      profiles(id, username, avatar_url)
    `)
    .order('created_at', { ascending: false })
    .range(page * limit, (page + 1) * limit - 1);

  if (error) throw error;

  return (data ?? []).map((v: Record<string, unknown>) => ({
    id: v.id as string,
    url: v.url as string,
    thumbnail: v.thumbnail as string,
    caption: v.caption as string,
    likes: v.likes as number,
    comments: v.comments as number,
    shares: v.shares as number,
    duration: v.duration as number,
    tags: (v.tags as string[]) ?? [],
    mixTrackUrl: v.mix_track_url as string | undefined,
    createdAt: v.created_at as string,
    author: {
      id: (v.profiles as Record<string, unknown>)?.id as string ?? '',
      username: (v.profiles as Record<string, unknown>)?.username as string ?? 'unknown',
      avatar: (v.profiles as Record<string, unknown>)?.avatar_url as string ?? '',
    },
  }));
}

// Like a video (optimistic update backed by Supabase RPC)
export async function likeVideo(videoId: string): Promise<void> {
  const { error } = await supabase.rpc('increment_likes', { video_id: videoId });
  if (error) throw error;
}

// Subscribe to real-time agent job updates
export function subscribeToJob(
  jobId: string,
  onUpdate: (status: string, result?: string) => void
) {
  return supabase
    .channel(`job:${jobId}`)
    .on(
      'postgres_changes',
      { event: 'UPDATE', schema: 'public', table: 'agent_jobs', filter: `id=eq.${jobId}` },
      (payload) => {
        const row = payload.new as { status: string; result?: string };
        onUpdate(row.status, row.result);
      }
    )
    .subscribe();
}
