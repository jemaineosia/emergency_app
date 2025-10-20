import 'dart:async';

import 'package:flutter/material.dart';

import '../models/emergency_contact.dart';
import '../services/phone_service.dart';

class CountdownScreen extends StatefulWidget {
  final EmergencyContact contact;
  final int countdownSeconds;

  const CountdownScreen({
    super.key,
    required this.contact,
    required this.countdownSeconds,
  });

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  late int _remainingSeconds;
  Timer? _timer;
  final PhoneService _phoneService = PhoneService();

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.countdownSeconds;
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        _makeEmergencyCall();
      }
    });
  }

  void _makeEmergencyCall() async {
    final success = await _phoneService.makeCall(widget.contact.contactNumber);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calling emergency contact...'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to make call. Please dial manually.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      Navigator.of(context).pop();
    }
  }

  void _cancelCall() {
    _timer?.cancel();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency call cancelled'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remainingSeconds / widget.countdownSeconds;

    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emergency, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                'EMERGENCY CALL',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 48),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.red,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '$_remainingSeconds',
                        style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const Text(
                        'seconds',
                        style: TextStyle(fontSize: 20, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        Icons.local_hospital,
                        'Type',
                        widget.contact.type.toUpperCase(),
                      ),
                      const Divider(),
                      _buildInfoRow(Icons.person, 'Name', widget.contact.name),
                      const Divider(),
                      _buildInfoRow(
                        Icons.phone,
                        'Number',
                        widget.contact.contactNumber,
                      ),
                      const Divider(),
                      _buildInfoRow(
                        Icons.location_on,
                        'Address',
                        widget.contact.address,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _cancelCall,
                  icon: const Icon(Icons.cancel, size: 28),
                  label: const Text(
                    'CANCEL CALL',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
