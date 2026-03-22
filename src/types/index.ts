export interface Video {
  id: string;
  url: string;
  thumbnail: string;
  author: {
    id: string;
    username: string;
    avatar: string;
  };
  caption: string;
  likes: number;
  comments: number;
  shares: number;
  duration: number;
  tags: string[];
  embedding?: number[]; // pgvector embedding
  mixTrackUrl?: string; // AutoMix secondary track
  createdAt: string;
}

export interface DJSettings {
  playbackSpeed: number;
  preservePitch: boolean;
  autoMixEnabled: boolean;
  autoMixVolume: number;
  originalVolume: number;
}

export interface DubSettings {
  targetLanguage: string;
  voicePersona: VoicePersona;
  isActive: boolean;
  dubAudioUrl?: string;
}

export type VoicePersona =
  | 'energetic'
  | 'calm'
  | 'deep_bass'
  | 'high_pitch'
  | 'synthesizer'
  | 'cloned';

export interface AgentJob {
  jobId: string;
  type: 'transcription' | 'translation' | 'tts' | 'music' | 'video_edit';
  status: 'pending' | 'running' | 'completed' | 'failed';
  result?: string;
  error?: string;
  createdAt: string;
}

export interface WebhookEvent {
  event: string;
  payload: Record<string, unknown>;
  timestamp: string;
}

export interface Language {
  code: string;
  label: string;
}

export const LANGUAGES: Language[] = [
  { code: 'es', label: 'Spanish' },
  { code: 'ja', label: 'Japanese' },
  { code: 'th', label: 'Thai' },
  { code: 'fr', label: 'French' },
  { code: 'de', label: 'German' },
  { code: 'pt', label: 'Portuguese' },
  { code: 'ko', label: 'Korean' },
  { code: 'zh', label: 'Chinese' },
  { code: 'ar', label: 'Arabic' },
  { code: 'hi', label: 'Hindi' },
];
