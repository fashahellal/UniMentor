import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'payment_page.dart';

// Mentee - Booking session page
class BookingPage extends StatefulWidget {
  final Map<String, dynamic> mentorData;

  const BookingPage({super.key, required this.mentorData});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedMeetingType;

  // Calculate rates based on modes
  String _calculateTargetAmount() {
    final String rateType =
        widget.mentorData['RateType'] ??
        widget.mentorData['rateType'] ??
        'flat';

    if (rateType == 'split') {
      if (_selectedMeetingType == "Online") {
        String onlineRate =
            (widget.mentorData['OnlineRate'] ??
                    widget.mentorData['onlineRate'] ??
                    "40.00")
                .toString();
        return onlineRate.replaceAll("RM ", "").trim();
      } else if (_selectedMeetingType == "Physical") {
        String physicalRate =
            (widget.mentorData['PhysicalRate'] ??
                    widget.mentorData['physicalRate'] ??
                    "60.00")
                .toString();
        return physicalRate.replaceAll("RM ", "").trim();
      }
    }

    String flatRate =
        (widget.mentorData['Rate'] ?? widget.mentorData['rate'] ?? "50.00")
            .toString();
    return flatRate.replaceAll("RM ", "").trim();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
      if (context.mounted) {
        _showLearningModeSelectionDialog(context);
      }
    }
  }

  // Price based on mode type
  void _showLearningModeSelectionDialog(BuildContext context) {
    final String rateType =
        widget.mentorData['RateType'] ??
        widget.mentorData['rateType'] ??
        'flat';

    final String onlineRate =
        (widget.mentorData['OnlineRate'] ??
                widget.mentorData['onlineRate'] ??
                '40.00')
            .toString()
            .replaceAll("RM ", "");
    final String physicalRate =
        (widget.mentorData['PhysicalRate'] ??
                widget.mentorData['physicalRate'] ??
                '60.00')
            .toString()
            .replaceAll("RM ", "");
    final String flatRate =
        (widget.mentorData['Rate'] ?? widget.mentorData['rate'] ?? '50.00')
            .toString()
            .replaceAll("RM ", "");

    final String onlinePriceText = rateType == 'split'
        ? " (RM $onlineRate)"
        : " (RM $flatRate)";
    final String physicalPriceText = rateType == 'split'
        ? " (RM $physicalRate)"
        : " (RM $flatRate)";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Select Learning Mode",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
          ),
          content: const Text(
            "Please select your preferred option for this session:",
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.video_camera_front, color: Colors.purple),
              label: Text(
                "Online Meeting$onlinePriceText",
                style: const TextStyle(color: Colors.purple),
              ),
              onPressed: () {
                setState(() => _selectedMeetingType = "Online");
                Navigator.pop(context);
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.location_on, color: Colors.purple),
              label: Text(
                "Physical Meetup$physicalPriceText",
                style: const TextStyle(color: Colors.purple),
              ),
              onPressed: () {
                setState(() => _selectedMeetingType = "Physical");
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // Confirmation message
  void _askInitialConfirmation() {
    String formattedDate =
        "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}";
    String formattedTime = _selectedTime!.format(context);
    String exactCost = _calculateTargetAmount();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Session"),
        content: Text(
          "Are you sure you want to book an $_selectedMeetingType session on $formattedDate at $formattedTime?\n\nTotal Due: RM $exactCost",
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () {
              Navigator.pop(context);
              _navigateToPayment();
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Redirected to payment page
  void _navigateToPayment() {
    final user = FirebaseAuth.instance.currentUser;
    DateTime combinedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    final bookingData = {
      'menteeId': user?.uid,
      'mentorId': widget.mentorData['uid'],
      'mentorName': widget.mentorData['username'],
      'subject': widget.mentorData['subject'],
      'sessionDateTime': combinedDateTime,
      'meetingType': _selectedMeetingType,
      'amount': "RM ${_calculateTargetAmount()}",
    };
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(bookingData: bookingData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool canChooseTime = _selectedDate != null;
    bool canChooseMeetingType = _selectedDate != null && _selectedTime != null;
    bool canConfirm =
        _selectedDate != null &&
        _selectedTime != null &&
        _selectedMeetingType != null;

    final String computedRateDisplay = canConfirm
        ? "RM ${_calculateTargetAmount()}"
        : "Calculating...";

    final String rateType =
        widget.mentorData['RateType'] ??
        widget.mentorData['rateType'] ??
        'flat';
    final String onlineRate =
        (widget.mentorData['OnlineRate'] ??
                widget.mentorData['onlineRate'] ??
                '40.00')
            .toString()
            .replaceAll("RM ", "");
    final String physicalRate =
        (widget.mentorData['PhysicalRate'] ??
                widget.mentorData['physicalRate'] ??
                '60.00')
            .toString()
            .replaceAll("RM ", "");
    final String flatRate =
        (widget.mentorData['Rate'] ?? widget.mentorData['rate'] ?? '50.00')
            .toString()
            .replaceAll("RM ", "");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Details"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            children: [
              const Icon(Icons.event_available, size: 70, color: Colors.purple),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectDate(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: _selectedDate != null
                                ? Colors.purple
                                : Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedDate == null
                                ? "Choose Date"
                                : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: canChooseTime
                          ? () => _selectTime(context)
                          : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: _selectedTime != null
                                ? Colors.purple
                                : Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedTime == null
                                ? "Choose Time"
                                : _selectedTime!.format(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 35),
              const Divider(),
              const SizedBox(height: 25),
              const Text(
                "Selected Learning Option",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _meetingTypeOptionCard(
                    type: "Online",
                    label: "Online Meeting",
                    priceLabel: rateType == 'split'
                        ? "RM $onlineRate"
                        : "RM $flatRate",
                    icon: Icons.video_camera_front,
                    enabled: canChooseMeetingType,
                  ),
                  const SizedBox(width: 16),
                  _meetingTypeOptionCard(
                    type: "Physical",
                    label: "Physical Meetup",
                    priceLabel: rateType == 'split'
                        ? "RM $physicalRate"
                        : "RM $flatRate",
                    icon: Icons.location_on,
                    enabled: canChooseMeetingType,
                  ),
                ],
              ),
              if (canConfirm) ...[
                const SizedBox(height: 35),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Calculated Session Price:",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        computedRateDisplay,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: canConfirm ? _askInitialConfirmation : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Confirm Booking",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meetingTypeOptionCard({
    required String type,
    required String label,
    String? priceLabel,
    required IconData icon,
    required bool enabled,
  }) {
    bool isSelected = _selectedMeetingType == type;
    return Expanded(
      child: InkWell(
        onTap: enabled
            ? () => setState(() => _selectedMeetingType = type)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: !enabled
                ? Colors.grey.shade100
                : isSelected
                ? Colors.purple.withOpacity(0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.purple : Colors.grey.shade300,
              width: isSelected ? 2.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: !enabled
                    ? Colors.grey
                    : isSelected
                    ? Colors.purple
                    : Colors.grey,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: !enabled
                      ? Colors.grey
                      : isSelected
                      ? Colors.purple
                      : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              if (priceLabel != null && enabled) ...[
                const SizedBox(height: 4),
                Text(
                  priceLabel,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.purple.shade700
                        : Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
