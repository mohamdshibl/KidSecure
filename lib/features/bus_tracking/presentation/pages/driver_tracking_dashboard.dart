import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/driver_location_cubit.dart';
import '../cubit/driver_location_state.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';

class DriverTrackingDashboard extends StatelessWidget {
  final String busId;
  final String driverId;

  const DriverTrackingDashboard({
    super.key,
    required this.busId,
    required this.driverId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
      ),
      body: BlocConsumer<DriverLocationCubit, DriverLocationState>(
        listener: (context, state) {
          if (state is DriverLocationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, trackingState) {
          final isTracking = trackingState is DriverLocationTracking;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                color: isTracking ? Colors.green.shade100 : Colors.grey.shade200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTracking ? 'Status: TRIPPING ACTIVE' : 'Status: IDLE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isTracking ? Colors.green.shade800 : Colors.black54,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isTracking ? Colors.red : Colors.green,
                      ),
                      onPressed: () {
                        if (isTracking) {
                          context.read<DriverLocationCubit>().endTrip();
                        } else {
                          context.read<DriverLocationCubit>().startTrip(busId, driverId);
                        }
                      },
                      child: Text(isTracking ? 'End Trip' : 'Start Trip'),
                    ),
                  ],
                ),
              ),
              if (trackingState is DriverLocationTracking)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Current GPS: ${trackingState.currentLat.toStringAsFixed(4)}, ${trackingState.currentLng.toStringAsFixed(4)}'),
                ),
              const Divider(thickness: 2),
              Expanded(
                child: _StudentNotificationList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StudentNotificationList extends StatelessWidget {
  // Mock data for students assigned to this bus.
  // In a real scenario, this would come from a StudentsRepository.
  final List<Map<String, String>> students = [
    {'id': 'S1', 'name': 'Ahmed Ali', 'parentId': 'P1'},
    {'id': 'S2', 'name': 'Sara Khalid', 'parentId': 'P2'},
    {'id': 'S3', 'name': 'Omar Sami', 'parentId': 'P3'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student: ${student['name']}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                BlocConsumer<NotificationCubit, NotificationState>(
                  listener: (context, state) {
                    if (state is NotificationSentSuccess && state.studentId == student['id']) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Notified parents of ${student['name']}')),
                      );
                    } else if (state is NotificationSentFailure && state.studentId == student['id']) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.error), backgroundColor: Colors.red),
                      );
                    }
                  },
                  builder: (context, state) {
                    final isSending = state is NotificationSending && state.studentId == student['id'];

                    if (isSending) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<NotificationCubit>().sendNotification(
                              studentId: student['id']!,
                              parentId: student['parentId']!,
                              studentName: student['name']!,
                              type: 'NEAR',
                            );
                          },
                          icon: const Icon(Icons.directions_bus),
                          label: const Text('Bus is Near'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade300),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<NotificationCubit>().sendNotification(
                              studentId: student['id']!,
                              parentId: student['parentId']!,
                              studentName: student['name']!,
                              type: 'ARRIVING',
                            );
                          },
                          icon: const Icon(Icons.timer),
                          label: const Text('1 min Away'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade300),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
