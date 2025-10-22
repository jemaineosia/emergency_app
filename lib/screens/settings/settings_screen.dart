import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/background_service_provider.dart';
import '../../services/supabase_service.dart';

/// Settings screen for configuring app behavior
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoUpdateEnabled = true;
  int _updateIntervalMinutes = 60;
  double _locationRadiusKm = 10.0;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final supabase = SupabaseService.instance;
      final settings = await supabase.getUserSettings();

      if (settings != null) {
        setState(() {
          _autoUpdateEnabled = settings['auto_update_enabled'] ?? true;
          _updateIntervalMinutes = settings['update_interval_minutes'] ?? 60;
          _locationRadiusKm = (settings['location_radius_km'] ?? 10.0)
              .toDouble();
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final supabase = SupabaseService.instance;
      await supabase.upsertUserSettings({
        'auto_update_enabled': _autoUpdateEnabled,
        'update_interval_minutes': _updateIntervalMinutes,
        'location_radius_km': _locationRadiusKm,
      });

      // Update background service schedule
      final backgroundProvider = context.read<BackgroundServiceProvider>();
      await backgroundProvider.updateFromSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveSettings,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildBackgroundUpdateSection(),
                const Divider(),
                _buildUpdateIntervalSection(),
                const Divider(),
                _buildLocationRadiusSection(),
                const Divider(),
                _buildAccountSection(),
              ],
            ),
    );
  }

  Widget _buildBackgroundUpdateSection() {
    return SwitchListTile(
      title: const Text('Automatic Updates'),
      subtitle: const Text('Update contacts when location changes'),
      value: _autoUpdateEnabled,
      onChanged: (value) {
        setState(() {
          _autoUpdateEnabled = value;
        });
      },
    );
  }

  Widget _buildUpdateIntervalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: const Text('Update Interval'),
          subtitle: Text(
            'Check location every ${_formatInterval(_updateIntervalMinutes)}',
          ),
        ),
        Slider(
          value: _updateIntervalMinutes.toDouble(),
          min: 15,
          max: 1440,
          divisions: 20,
          label: _formatInterval(_updateIntervalMinutes),
          onChanged: (value) {
            setState(() {
              _updateIntervalMinutes = value.toInt();
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('15 min', style: Theme.of(context).textTheme.bodySmall),
              Text('24 hours', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLocationRadiusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: const Text('Search Radius'),
          subtitle: Text(
            'Find services within ${_locationRadiusKm.toStringAsFixed(1)} km',
          ),
        ),
        Slider(
          value: _locationRadiusKm,
          min: 1,
          max: 50,
          divisions: 49,
          label: '${_locationRadiusKm.toStringAsFixed(1)} km',
          onChanged: (value) {
            setState(() {
              _locationRadiusKm = value;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 km', style: Theme.of(context).textTheme.bodySmall),
              Text('50 km', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Account'),
              subtitle: Text(
                authProvider.userProfile?.email ??
                    authProvider.userProfile?.displayName ??
                    'Anonymous User',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  await authProvider.signOut();
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _formatInterval(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else if (minutes == 60) {
      return '1 hour';
    } else if (minutes < 1440) {
      final hours = (minutes / 60).toStringAsFixed(1);
      return '$hours hours';
    } else {
      return '24 hours';
    }
  }
}
