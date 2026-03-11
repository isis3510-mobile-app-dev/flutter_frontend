import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/utils/context_extensions.dart';
import 'package:flutter_frontend/core/utils/string_extensions.dart';

class VaccineCard extends StatelessWidget {
  const VaccineCard({
    super.key,
    required this.vaccineName,
    required this.petName,
    required this.dateAdministered,
    required this.status,
    this.administeredBy,
  });

  final String vaccineName;
  final String petName;
  final DateTime dateAdministered;
  final String status;
  final String? administeredBy;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.secondary,
      shadowColor: AppColors.grey100,
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircleAvatar(radius: 24, backgroundImage: NetworkImage('https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRJA50hPAm9xtoIcWvkRRffK-yhDOEFpTNgVg&s')),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vaccineName,
                        style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$petName · ${dateAdministered.toLocal().toString().split(' ')[0]}',
                    style: context.textTheme.bodySmall,
                  ),
                  if (administeredBy != null)
                    Text(
                      administeredBy??'',
                      style: context.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: status == 'active' ? Color(0xFFE8F5E9) : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.capitalize,
                style: TextStyle(
                  color: status == 'active' ? const Color(0xFF2E7D32) : const Color.fromARGB(255, 144, 39, 31),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}