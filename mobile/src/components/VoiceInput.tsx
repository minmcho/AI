import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { Audio } from 'expo-av';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { transcribeAudio } from '../services/whisperService';

interface Props {
  onTranscript: (transcript: string, language: string) => void;
}

const VoiceInput: React.FC<Props> = ({ onTranscript }) => {
  const [isRecording, setIsRecording] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [recording, setRecording] = useState<Audio.Recording | null>(null);
  const [selectedLanguage, setSelectedLanguage] = useState<'es' | 'my'>('es');

  const startRecording = async () => {
    try {
      const { status } = await Audio.requestPermissionsAsync();
      if (status !== 'granted') {
        Alert.alert('Permission Denied', 'Microphone access is required');
        return;
      }

      await Audio.setAudioModeAsync({
        allowsRecordingIOS: true,
        playsInSilentModeIOS: true,
      });

      const { recording: newRecording } = await Audio.Recording.createAsync(
        Audio.RecordingOptionsPresets.HIGH_QUALITY
      );

      setRecording(newRecording);
      setIsRecording(true);
    } catch (error) {
      console.error('Failed to start recording', error);
      Alert.alert('Error', 'Failed to start recording');
    }
  };

  const stopRecording = async () => {
    if (!recording) return;

    try {
      setIsRecording(false);
      setIsProcessing(true);

      await recording.stopAndUnloadAsync();
      const uri = recording.getURI();

      if (uri) {
        const transcript = await transcribeAudio(uri, selectedLanguage);
        onTranscript(transcript, selectedLanguage);
      }

      setRecording(null);
    } catch (error) {
      console.error('Failed to stop recording', error);
      Alert.alert('Error', 'Failed to process audio');
    } finally {
      setIsProcessing(false);
    }
  };

  const languages = [
    { code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸' },
    { code: 'my', name: 'Burmese', nativeName: 'မြန်မာ', flag: '🇲🇲' },
  ];

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Select Language & Speak</Text>

      <View style={styles.languageSelector}>
        {languages.map((lang) => (
          <TouchableOpacity
            key={lang.code}
            style={[
              styles.langButton,
              selectedLanguage === lang.code && styles.langButtonActive,
            ]}
            onPress={() => setSelectedLanguage(lang.code as 'es' | 'my')}
            disabled={isRecording || isProcessing}
          >
            <Text style={styles.langFlag}>{lang.flag}</Text>
            <Text style={styles.langName}>{lang.nativeName}</Text>
          </TouchableOpacity>
        ))}
      </View>

      <View style={styles.recordingContainer}>
        {isProcessing ? (
          <View style={styles.processingContainer}>
            <ActivityIndicator size="large" color="#2563eb" />
            <Text style={styles.processingText}>Processing audio...</Text>
          </View>
        ) : (
          <TouchableOpacity
            style={[
              styles.recordButton,
              isRecording && styles.recordButtonActive,
            ]}
            onPress={isRecording ? stopRecording : startRecording}
          >
            <Text style={styles.recordIcon}>
              {isRecording ? '⏹️' : '🎤'}
            </Text>
            <Text style={styles.recordText}>
              {isRecording ? 'Tap to Stop' : 'Tap to Record'}
            </Text>
            {isRecording && (
              <View style={styles.recordingIndicator}>
                <View style={styles.recordingDot} />
                <Text style={styles.recordingText}>Recording...</Text>
              </View>
            )}
          </TouchableOpacity>
        )}
      </View>

      <View style={styles.exampleQuestions}>
        <Text style={styles.exampleTitle}>Example Questions:</Text>
        {selectedLanguage === 'es' ? (
          <>
            <Text style={styles.exampleText}>• "¿Es esto peligroso?"</Text>
            <Text style={styles.exampleText}>• "¿Qué debo hacer?"</Text>
            <Text style={styles.exampleText}>• "¿Necesita tratamiento inmediato?"</Text>
          </>
        ) : (
          <>
            <Text style={styles.exampleText}>• "ဒါက အန္တရာယ်ရှိပါသလား။"</Text>
            <Text style={styles.exampleText}>• "ဘာလုပ်သင့်ပါသလဲ။"</Text>
            <Text style={styles.exampleText}>• "ချက်ခြင်း ကုသမှု လိုအပ်ပါသလား။"</Text>
          </>
        )}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#fff',
    padding: 20,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: '#e2e8f0',
  },
  title: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1e293b',
    marginBottom: 15,
    textAlign: 'center',
  },
  languageSelector: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 20,
  },
  langButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    padding: 12,
    borderRadius: 8,
    backgroundColor: '#f1f5f9',
    borderWidth: 2,
    borderColor: '#e2e8f0',
  },
  langButtonActive: {
    backgroundColor: '#eff6ff',
    borderColor: '#2563eb',
  },
  langFlag: {
    fontSize: 24,
  },
  langName: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1e293b',
  },
  recordingContainer: {
    alignItems: 'center',
    marginBottom: 20,
  },
  recordButton: {
    width: 160,
    height: 160,
    borderRadius: 80,
    backgroundColor: '#2563eb',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#2563eb',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 4,
  },
  recordButtonActive: {
    backgroundColor: '#dc2626',
    shadowColor: '#dc2626',
  },
  recordIcon: {
    fontSize: 48,
    marginBottom: 8,
  },
  recordText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  recordingIndicator: {
    marginTop: 12,
    alignItems: 'center',
  },
  recordingDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: '#fff',
    marginBottom: 4,
  },
  recordingText: {
    color: '#fff',
    fontSize: 12,
  },
  processingContainer: {
    alignItems: 'center',
    padding: 40,
  },
  processingText: {
    marginTop: 16,
    fontSize: 16,
    color: '#64748b',
  },
  exampleQuestions: {
    backgroundColor: '#f8fafc',
    padding: 16,
    borderRadius: 8,
  },
  exampleTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1e293b',
    marginBottom: 8,
  },
  exampleText: {
    fontSize: 13,
    color: '#64748b',
    marginBottom: 4,
  },
});

export default VoiceInput;
