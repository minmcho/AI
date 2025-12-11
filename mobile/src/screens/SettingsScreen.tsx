import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Switch,
  Alert,
} from 'react-native';
import {
  loadSettings,
  saveSettings,
  getStorageStats,
  clearAllData,
} from '../services/storageService';

const SettingsScreen: React.FC = () => {
  const [settings, setSettings] = useState({
    defaultLanguage: 'es',
    autoSaveAnalyses: true,
    autoDeleteAfterDays: 30,
    enableAudioPlayback: true,
    privacyMode: true,
  });
  const [stats, setStats] = useState({
    analysesCount: 0,
    storageUsed: '0 KB',
  });

  useEffect(() => {
    loadAppSettings();
    loadStats();
  }, []);

  const loadAppSettings = async () => {
    const loaded = await loadSettings();
    setSettings(loaded);
  };

  const loadStats = async () => {
    const storageStats = await getStorageStats();
    setStats(storageStats);
  };

  const updateSetting = async (key: string, value: any) => {
    const newSettings = { ...settings, [key]: value };
    setSettings(newSettings);
    await saveSettings(newSettings);
  };

  const handleClearData = () => {
    Alert.alert(
      'Clear All Data',
      'This will permanently delete all saved analyses and reset the app. This action cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Clear All',
          style: 'destructive',
          onPress: async () => {
            await clearAllData();
            await loadStats();
            Alert.alert('Success', 'All data has been cleared');
          },
        },
      ]
    );
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.content}>
        {/* Language Settings */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>🌍 Language Preferences</Text>
          <View style={styles.card}>
            <Text style={styles.label}>Default Language</Text>
            <View style={styles.languageButtons}>
              <TouchableOpacity
                style={[
                  styles.langButton,
                  settings.defaultLanguage === 'es' && styles.langButtonActive,
                ]}
                onPress={() => updateSetting('defaultLanguage', 'es')}
              >
                <Text style={styles.langEmoji}>🇪🇸</Text>
                <Text style={styles.langText}>Spanish</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[
                  styles.langButton,
                  settings.defaultLanguage === 'my' && styles.langButtonActive,
                ]}
                onPress={() => updateSetting('defaultLanguage', 'my')}
              >
                <Text style={styles.langEmoji}>🇲🇲</Text>
                <Text style={styles.langText}>Burmese</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>

        {/* Privacy Settings */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>🔒 Privacy & Data</Text>

          <View style={styles.card}>
            <View style={styles.settingRow}>
              <View style={styles.settingInfo}>
                <Text style={styles.settingLabel}>Privacy Mode</Text>
                <Text style={styles.settingDescription}>
                  All data processed locally, never sent to servers
                </Text>
              </View>
              <Switch
                value={settings.privacyMode}
                onValueChange={(value) => updateSetting('privacyMode', value)}
                trackColor={{ false: '#d1d5db', true: '#86efac' }}
                thumbColor={settings.privacyMode ? '#16a34a' : '#f3f4f6'}
              />
            </View>
          </View>

          <View style={styles.card}>
            <View style={styles.settingRow}>
              <View style={styles.settingInfo}>
                <Text style={styles.settingLabel}>Auto-Save Analyses</Text>
                <Text style={styles.settingDescription}>
                  Automatically save analysis results locally
                </Text>
              </View>
              <Switch
                value={settings.autoSaveAnalyses}
                onValueChange={(value) => updateSetting('autoSaveAnalyses', value)}
                trackColor={{ false: '#d1d5db', true: '#93c5fd' }}
                thumbColor={settings.autoSaveAnalyses ? '#2563eb' : '#f3f4f6'}
              />
            </View>
          </View>

          <View style={styles.card}>
            <Text style={styles.label}>Auto-Delete After (Days)</Text>
            <Text style={styles.description}>
              Automatically delete analyses older than {settings.autoDeleteAfterDays} days
            </Text>
            <View style={styles.daysButtons}>
              {[7, 14, 30, 60].map((days) => (
                <TouchableOpacity
                  key={days}
                  style={[
                    styles.dayButton,
                    settings.autoDeleteAfterDays === days && styles.dayButtonActive,
                  ]}
                  onPress={() => updateSetting('autoDeleteAfterDays', days)}
                >
                  <Text
                    style={[
                      styles.dayButtonText,
                      settings.autoDeleteAfterDays === days &&
                        styles.dayButtonTextActive,
                    ]}
                  >
                    {days}d
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>
        </View>

        {/* Audio Settings */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>🔊 Audio</Text>
          <View style={styles.card}>
            <View style={styles.settingRow}>
              <View style={styles.settingInfo}>
                <Text style={styles.settingLabel}>Enable Audio Playback</Text>
                <Text style={styles.settingDescription}>
                  Read analysis results aloud
                </Text>
              </View>
              <Switch
                value={settings.enableAudioPlayback}
                onValueChange={(value) =>
                  updateSetting('enableAudioPlayback', value)
                }
                trackColor={{ false: '#d1d5db', true: '#93c5fd' }}
                thumbColor={settings.enableAudioPlayback ? '#2563eb' : '#f3f4f6'}
              />
            </View>
          </View>
        </View>

        {/* Storage Info */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>💾 Storage</Text>
          <View style={styles.card}>
            <View style={styles.statRow}>
              <Text style={styles.statLabel}>Saved Analyses</Text>
              <Text style={styles.statValue}>{stats.analysesCount}</Text>
            </View>
            <View style={styles.statRow}>
              <Text style={styles.statLabel}>Storage Used</Text>
              <Text style={styles.statValue}>{stats.storageUsed}</Text>
            </View>
          </View>

          <TouchableOpacity style={styles.dangerButton} onPress={handleClearData}>
            <Text style={styles.dangerButtonText}>🗑️ Clear All Data</Text>
          </TouchableOpacity>
        </View>

        {/* About */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>ℹ️ About</Text>
          <View style={styles.card}>
            <Text style={styles.aboutText}>
              Health Rash AI v1.0.0
            </Text>
            <Text style={styles.aboutDescription}>
              Open-source AI-powered medical assistance for healthcare workers in
              underserved communities.
            </Text>
            <Text style={styles.aboutFeature}>
              ✓ 100% Privacy-Preserving
            </Text>
            <Text style={styles.aboutFeature}>
              ✓ All Processing On-Device
            </Text>
            <Text style={styles.aboutFeature}>
              ✓ Open-Source AI Models
            </Text>
            <Text style={styles.aboutFeature}>
              ✓ Multilingual Support
            </Text>
          </View>
        </View>

        {/* Disclaimer */}
        <View style={styles.disclaimer}>
          <Text style={styles.disclaimerText}>
            This application is intended as a support tool for healthcare workers
            and does not replace professional medical judgment. Always follow
            established medical protocols and guidelines.
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
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1e293b',
    marginBottom: 12,
  },
  card: {
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 12,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1e293b',
    marginBottom: 8,
  },
  description: {
    fontSize: 14,
    color: '#64748b',
    marginBottom: 12,
  },
  languageButtons: {
    flexDirection: 'row',
    gap: 12,
  },
  langButton: {
    flex: 1,
    padding: 16,
    borderRadius: 8,
    backgroundColor: '#f1f5f9',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#e2e8f0',
  },
  langButtonActive: {
    backgroundColor: '#eff6ff',
    borderColor: '#2563eb',
  },
  langEmoji: {
    fontSize: 32,
    marginBottom: 8,
  },
  langText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1e293b',
  },
  settingRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  settingInfo: {
    flex: 1,
    marginRight: 12,
  },
  settingLabel: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1e293b',
    marginBottom: 4,
  },
  settingDescription: {
    fontSize: 13,
    color: '#64748b',
  },
  daysButtons: {
    flexDirection: 'row',
    gap: 8,
  },
  dayButton: {
    flex: 1,
    padding: 12,
    borderRadius: 8,
    backgroundColor: '#f1f5f9',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#e2e8f0',
  },
  dayButtonActive: {
    backgroundColor: '#eff6ff',
    borderColor: '#2563eb',
  },
  dayButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#64748b',
  },
  dayButtonTextActive: {
    color: '#2563eb',
  },
  statRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#f1f5f9',
  },
  statLabel: {
    fontSize: 15,
    color: '#64748b',
  },
  statValue: {
    fontSize: 15,
    fontWeight: '600',
    color: '#1e293b',
  },
  dangerButton: {
    backgroundColor: '#fef2f2',
    padding: 16,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: '#fecaca',
    alignItems: 'center',
  },
  dangerButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#dc2626',
  },
  aboutText: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1e293b',
    marginBottom: 8,
  },
  aboutDescription: {
    fontSize: 14,
    color: '#64748b',
    marginBottom: 16,
    lineHeight: 20,
  },
  aboutFeature: {
    fontSize: 14,
    color: '#16a34a',
    marginBottom: 6,
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

export default SettingsScreen;
