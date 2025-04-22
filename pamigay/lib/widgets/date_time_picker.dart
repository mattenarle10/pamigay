import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pamigay/utils/constants.dart';

class DatePickerField extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final String label;
  final String format;
  final Color borderColor;
  final Color textColor;

  const DatePickerField({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
    this.label = 'Select Date',
    this.format = 'MMM dd, yyyy',
    this.borderColor = Colors.grey,
    this.textColor = Colors.black87,
  }) : super(key: key);

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: PamigayColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat(format).format(selectedDate),
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontFamily: 'Montserrat',
                  ),
                ),
                Icon(Icons.calendar_today, color: PamigayColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TimePickerField extends StatelessWidget {
  final TimeOfDay selectedTime;
  final Function(TimeOfDay) onTimeSelected;
  final String label;
  final Color borderColor;
  final Color textColor;

  const TimePickerField({
    Key? key,
    required this.selectedTime,
    required this.onTimeSelected,
    this.label = '',
    this.borderColor = Colors.grey,
    this.textColor = Colors.black87,
  }) : super(key: key);

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: PamigayColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    final format = DateFormat.jm(); // 5:08 PM
    return format.format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        GestureDetector(
          onTap: () => _selectTime(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTimeOfDay(selectedTime),
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontFamily: 'Montserrat',
                  ),
                ),
                Icon(Icons.access_time, color: PamigayColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PickupWindowSelector extends StatelessWidget {
  final DateTime selectedDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final Function(DateTime) onDateSelected;
  final Function(TimeOfDay) onStartTimeSelected;
  final Function(TimeOfDay) onEndTimeSelected;
  final Color borderColor;
  final Color textColor;

  const PickupWindowSelector({
    Key? key,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.onDateSelected,
    required this.onStartTimeSelected,
    required this.onEndTimeSelected,
    this.borderColor = Colors.grey,
    this.textColor = Colors.black87,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pickup Window:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        const SizedBox(height: 8),
        DatePickerField(
          selectedDate: selectedDate,
          onDateSelected: onDateSelected,
          label: '',
          borderColor: borderColor,
          textColor: textColor,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TimePickerField(
                selectedTime: startTime,
                onTimeSelected: onStartTimeSelected,
                borderColor: borderColor,
                textColor: textColor,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'to',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
            Expanded(
              child: TimePickerField(
                selectedTime: endTime,
                onTimeSelected: onEndTimeSelected,
                borderColor: borderColor,
                textColor: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
