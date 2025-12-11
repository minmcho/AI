import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { RouteProp } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';
import { RootStackParamList } from '../../App';
import * as Speech from 'expo-speech';
import { analyzeRashImage } from '../services/visionService';
import { generateMedicalResponse } from '../services/medicalLLMService';
import { saveAnalysisToStorage } from '../services/storageService';

type AnalysisScreenRouteProp = RouteProp<RootStackParamList, 'Analysis'>;
type AnalysisScreenNavigationProp = StackNavigationProp<
  RootStackParamList,
  'Analysis'
>;

interface Props {
  route: AnalysisScreenRouteProp;
  navigation: AnalysisScreenNavigationProp;
}

interface AnalysisResult {
  visualAnalysis: string;
  severity: 'low' | 'medium' | 'high';
  response: string;
  careInstructions: string[];
  seekMedicalAttention: boolean;
}

const AnalysisScreen: React.FC<Props> = ({ route, navigation }) => {
  const { imageUri, question, language } = route.params;
  const [isAnalyzing, setIsAnalyzing] = useState(true);
  const [result, setResult] = useState<AnalysisResult | null>(null);
  const [isSpeaking, setIsSpeaking] = useState(false);

  useEffect(() => {
    performAnalysis();
  }, []);

  const performAnalysis = async () => {
    try {
      setIsAnalyzing(true);

      // Step 1: Analyze the image with vision AI
      const visualAnalysis = await analyzeRashImage(imageUri);

      // Step 2: Generate medical response based on visual analysis and question
      const medicalResponse = await generateMedicalResponse(
        visualAnalysis,
        question,
        language
      );

      // Step 3: Parse and structure the response
      const analysisResult: AnalysisResult = {
        visualAnalysis: visualAnalysis.description,
        severity: visualAnalysis.severity,
        response: medicalResponse.answer,
        careInstructions: medicalResponse.careInstructions,
        seekMedicalAttention: medicalResponse.seekMedicalAttention,
      };

      setResult(analysisResult);

      // Save to local storage for privacy
      await saveAnalysisToStorage({
        timestamp: new Date().toISOString(),
        question,
        language,
        result: analysisResult,
      });
    } catch (error) {
      console.error('Analysis error:', error);
      Alert.alert(
        'Analysis Error',
        'Failed to analyze the image. Please try again.'
      );
    } finally {
      setIsAnalyzing(false);
    }
  };

  const speakResponse = () => {
    if (!result) return;

    const languageCode = language === 'es' ? 'es-ES' : 'my-MM';
    const textToSpeak = `${result.response}\n\n${result.careInstructions.join('. ')}`;

    setIsSpeaking(true);

    Speech.speak(textToSpeak, {
      language: languageCode,
      onDone: () => setIsSpeaking(false),
      onStopped: () => setIsSpeaking(false),
      onError: () => {
        setIsSpeaking(false);
        Alert.alert('Error', 'Text-to-speech failed');
      },
    });
  };

  const stopSpeaking = () => {
    Speech.stop();
    setIsSpeaking(false);
  };

  if (isAnalyzing) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#2563eb" />
        <Text style={styles.loadingTitle}>Analyzing...</Text>
        <View style={styles.loadingSteps}>
          <Text style={styles.loadingStep}>🔍 Analyzing rash image</Text>
          <Text style={styles.loadingStep}>🤖 Processing with AI</Text>
          <Text style={styles.loadingStep}>📋 Generating care instructions</Text>
        </View>
        <Text style={styles.loadingNote}>
          All processing is done locally on your device
        </Text>
      </View>
    );
  }

  if (!result) {
    return (
      <View style={styles.errorContainer}>
        <Text style={styles.errorIcon}>⚠️</Text>
        <Text style={styles.errorText}>Analysis failed</Text>
        <TouchableOpacity
          style={styles.retryButton}
          onPress={() => navigation.goBack()}
        >
          <Text style={styles.retryButtonText}>Go Back</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'low':
        return '#10b981';
      case 'medium':
        return '#f59e0b';
      case 'high':
        return '#ef4444';
      default:
        return '#64748b';
    }
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.content}>
        {/* Severity Badge */}
        <View
          style={[
            styles.severityBadge,
            { backgroundColor: getSeverityColor(result.severity) },
          ]}
        >
          <Text style={styles.severityText}>
            {result.severity.toUpperCase()} SEVERITY
          </Text>
        </View>

        {/* Question */}
        <View style={styles.section}>
          <Text style={styles.sectionIcon}>❓</Text>
          <Text style={styles.sectionTitle}>Your Question</Text>
          <Text style={styles.questionText}>{question}</Text>
        </View>

        {/* Medical Response */}
        <View style={styles.section}>
          <Text style={styles.sectionIcon}>🩺</Text>
          <Text style={styles.sectionTitle}>Medical Analysis</Text>
          <Text style={styles.responseText}>{result.response}</Text>
        </View>

        {/* Care Instructions */}
        <View style={styles.section}>
          <Text style={styles.sectionIcon}>📋</Text>
          <Text style={styles.sectionTitle}>Care Instructions</Text>
          {result.careInstructions.map((instruction, index) => (
            <View key={index} style={styles.instructionItem}>
              <Text style={styles.instructionNumber}>{index + 1}</Text>
              <Text style={styles.instructionText}>{instruction}</Text>
            </View>
          ))}
        </View>

        {/* Medical Attention Warning */}
        {result.seekMedicalAttention && (
          <View style={styles.warningBox}>
            <Text style={styles.warningIcon}>⚠️</Text>
            <Text style={styles.warningText}>
              Seek immediate medical attention. This appears to require
              professional evaluation.
            </Text>
          </View>
        )}

        {/* Audio Playback */}
        <View style={styles.audioSection}>
          <TouchableOpacity
            style={[styles.audioButton, isSpeaking && styles.audioButtonActive]}
            onPress={isSpeaking ? stopSpeaking : speakResponse}
          >
            <Text style={styles.audioIcon}>{isSpeaking ? '⏸️' : '🔊'}</Text>
            <Text style={styles.audioButtonText}>
              {isSpeaking ? 'Stop Audio' : 'Listen to Response'}
            </Text>
          </TouchableOpacity>
        </View>

        {/* Privacy Notice */}
        <View style={styles.privacyNotice}>
          <Text style={styles.privacyIcon}>🔒</Text>
          <Text style={styles.privacyText}>
            This analysis was processed entirely on your device. No data was
            sent to external servers.
          </Text>
        </View>

        {/* Actions */}
        <View style={styles.actions}>
          <TouchableOpacity
            style={styles.newAnalysisButton}
            onPress={() => navigation.navigate('Home')}
          >
            <Text style={styles.newAnalysisButtonText}>
              New Analysis
            </Text>
          </TouchableOpacity>
        </View>

        {/* Disclaimer */}
        <View style={styles.disclaimer}>
          <Text style={styles.disclaimerText}>
            ⚕️ This AI analysis is for informational purposes only and does not
            replace professional medical advice. Always consult with qualified
            healthcare providers for proper diagnosis and treatment.
          </Text>
        </View>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8fafc',
  },
  content: {
    padding: 20,
    paddingBottom: 40,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f8fafc',
    padding: 40,
  },
  loadingTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1e293b',
    marginTop: 20,
    marginBottom: 30,
  },
  loadingSteps: {
    alignItems: 'flex-start',
    marginBottom: 30,
  },
  loadingStep: {
    fontSize: 16,
    color: '#64748b',
    marginBottom: 12,
  },
  loadingNote: {
    fontSize: 14,
    color: '#10b981',
    textAlign: 'center',
    paddingHorizontal: 40,
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f8fafc',
    padding: 40,
  },
  errorIcon: {
    fontSize: 64,
    marginBottom: 20,
  },
  errorText: {
    fontSize: 20,
    color: '#ef4444',
    marginBottom: 30,
  },
  retryButton: {
    backgroundColor: '#2563eb',
    paddingHorizontal: 32,
    paddingVertical: 16,
    borderRadius: 12,
  },
  retryButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  severityBadge: {
    paddingVertical: 12,
    paddingHorizontal: 20,
    borderRadius: 8,
    alignSelf: 'center',
    marginBottom: 20,
  },
  severityText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: 'bold',
  },
  section: {
    backgroundColor: '#fff',
    padding: 20,
    borderRadius: 12,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  sectionIcon: {
    fontSize: 24,
    marginBottom: 8,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1e293b',
    marginBottom: 12,
  },
  questionText: {
    fontSize: 16,
    color: '#64748b',
    fontStyle: 'italic',
  },
  responseText: {
    fontSize: 16,
    color: '#1e293b',
    lineHeight: 24,
  },
  instructionItem: {
    flexDirection: 'row',
    marginBottom: 12,
  },
  instructionNumber: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: '#2563eb',
    color: '#fff',
    textAlign: 'center',
    lineHeight: 28,
    fontWeight: 'bold',
    marginRight: 12,
  },
  instructionText: {
    flex: 1,
    fontSize: 15,
    color: '#1e293b',
    lineHeight: 22,
  },
  warningBox: {
    backgroundColor: '#fef2f2',
    padding: 16,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: '#fecaca',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: 16,
  },
  warningIcon: {
    fontSize: 24,
  },
  warningText: {
    flex: 1,
    fontSize: 14,
    color: '#991b1b',
    fontWeight: '600',
    lineHeight: 20,
  },
  audioSection: {
    marginBottom: 16,
  },
  audioButton: {
    backgroundColor: '#2563eb',
    padding: 18,
    borderRadius: 12,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 12,
  },
  audioButtonActive: {
    backgroundColor: '#dc2626',
  },
  audioIcon: {
    fontSize: 24,
  },
  audioButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  privacyNotice: {
    backgroundColor: '#f0fdf4',
    padding: 16,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#86efac',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: 16,
  },
  privacyIcon: {
    fontSize: 20,
  },
  privacyText: {
    flex: 1,
    fontSize: 12,
    color: '#166534',
    lineHeight: 18,
  },
  actions: {
    marginBottom: 16,
  },
  newAnalysisButton: {
    backgroundColor: '#10b981',
    padding: 18,
    borderRadius: 12,
    alignItems: 'center',
  },
  newAnalysisButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  disclaimer: {
    backgroundColor: '#fef3c7',
    padding: 16,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#fde68a',
  },
  disclaimerText: {
    fontSize: 12,
    color: '#78350f',
    lineHeight: 18,
    textAlign: 'center',
  },
});

export default AnalysisScreen;
