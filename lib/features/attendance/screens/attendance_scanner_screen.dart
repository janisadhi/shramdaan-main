import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../shared/services/firestore_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/attendance_qr_payload.dart';

class AttendanceScannerScreen extends StatefulWidget {
  const AttendanceScannerScreen({super.key});

  @override
  State<AttendanceScannerScreen> createState() => _AttendanceScannerScreenState();
}

class _AttendanceScannerScreenState extends State<AttendanceScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final FirestoreService _firestoreService = FirestoreService();

  bool _isProcessing = false;
  String? _statusTitle;
  String? _statusMessage;
  bool _statusIsError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_isProcessing) {
      return;
    }

    final rawValue =
        capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });
    await _controller.stop();

    final payload = AttendanceQrPayload.tryParse(rawValue);
    if (payload == null) {
      _showStatus(
        title: 'Invalid QR',
        message: 'This code is not a valid Shramdaan attendance QR.',
        isError: true,
      );
      return;
    }

    if (payload.isExpired) {
      _showStatus(
        title: 'QR expired',
        message: 'Ask the organizer to refresh the attendance QR and try again.',
        isError: true,
      );
      return;
    }

    final event = await _firestoreService.getEventById(payload.eventId);
    if (event == null || event.status == 'archived') {
      _showStatus(
        title: 'Event unavailable',
        message: 'This event is no longer available for attendance scanning.',
        isError: true,
      );
      return;
    }

    if (!event.hasStarted) {
      _showStatus(
        title: 'Event not started',
        message: 'Check-in opens only when the event starts.',
        isError: true,
      );
      return;
    }

    if (event.isCompleted || !event.isAttendanceOpen) {
      _showStatus(
        title: 'Event ended',
        message: 'Check-in and check-out are no longer available for this event.',
        isError: true,
      );
      return;
    }

    final previousRecord = await _firestoreService.getAttendanceRecordForToday(
      volunteerId: currentUser.uid,
      eventId: payload.eventId,
    );
    final updatedRecord = await _firestoreService.recordAttendanceScan(
      volunteerId: currentUser.uid,
      eventId: payload.eventId,
    );

    final isCheckIn = previousRecord == null;
    final duration = _firestoreService.calculateAttendanceDuration(updatedRecord);

    _showStatus(
      title: isCheckIn ? 'Checked in' : 'Checked out',
      message: isCheckIn
          ? 'You are marked present for ${event.title}.'
          : duration == null
              ? 'Your attendance was updated for ${event.title}.'
              : 'Your final time for ${event.title} is ${_formatDuration(duration)}.',
    );
  }

  void _showStatus({
    required String title,
    required String message,
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }
    setState(() {
      _statusTitle = title;
      _statusMessage = message;
      _statusIsError = isError;
      _isProcessing = false;
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) {
      return '$minutes min';
    }
    if (minutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $minutes min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.neutral,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: const Text('Scan attendance'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.infoSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan the organizer QR',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'First scan checks you in. A later scan today updates your final check-out time.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.45,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _controller,
                          onDetect: _handleDetection,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x33005EB8),
                                Color(0x12005EB8),
                                Color(0x48005EB8),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Align QR inside the frame',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 244,
                            height: 244,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.18),
                                  blurRadius: 22,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_statusTitle != null && _statusMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _statusIsError
                              ? const Color(0xFFFEECEC)
                              : AppColors.successSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _statusIsError
                                ? const Color(0xFFF4C7C3)
                                : AppColors.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _statusTitle!,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: _statusIsError
                                        ? AppColors.error
                                        : AppColors.secondary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _statusMessage!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: _statusIsError
                                        ? AppColors.error
                                        : AppColors.textPrimary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      'Attendance only works after the event starts and before it ends.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _statusTitle = null;
                                _statusMessage = null;
                                _statusIsError = false;
                              });
                              _controller.start();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Ready again'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => Navigator.pop(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.done_rounded),
                            label: const Text('Done'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
