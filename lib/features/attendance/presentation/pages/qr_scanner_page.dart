import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/models/attendance_record.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Student QR', style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) async {
              if (_isProcessing) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() => _isProcessing = true);
                  await _handleScan(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          _buildOverlay(),
          if (_isProcessing)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Column(
      children: [
        Expanded(child: Container(color: Colors.black.withOpacity(0.5))),
        Row(
          children: [
            Expanded(child: Container(color: Colors.black.withOpacity(0.5))),
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            Expanded(child: Container(color: Colors.black.withOpacity(0.5))),
          ],
        ),
        Expanded(
          child: Container(
            color: Colors.black.withOpacity(0.5),
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            child: Text(
              'Align student QR code within the frame',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleScan(String qrCode) async {
    final repository = context.read<AttendanceRepository>();

    try {
      final student = await repository.getStudentByQrCode(qrCode);

      if (!mounted) return;

      if (student == null) {
        _showResult(context, 'Student not found', Colors.red);
      } else {
        // Simple logic: If checked in today, check out. Otherwise check in.
        // For a prototype, we'll just show a dialog to choose.
        _showAttendanceDialog(context, student);
      }
    } catch (e) {
      if (mounted) _showResult(context, 'Error processing scan', Colors.red);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showAttendanceDialog(BuildContext context, dynamic student) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              student.name,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Grade: ${student.grade}',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _register(
                      context,
                      student.id,
                      AttendanceStatus.checkIn,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Check In'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _register(
                      context,
                      student.id,
                      AttendanceStatus.checkOut,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Check Out'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _register(
    BuildContext context,
    String studentId,
    AttendanceStatus status,
  ) async {
    Navigator.pop(context); // Close bottom sheet

    final record = AttendanceRecord(
      id: '', // Firestore auto-id
      studentId: studentId,
      timestamp: DateTime.now(),
      status: status,
    );

    await context.read<AttendanceRepository>().recordAttendance(record);
    _showResult(
      context,
      'Success: ${status.toString().split('.').last}',
      Colors.green,
    );
  }

  void _showResult(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }
}
