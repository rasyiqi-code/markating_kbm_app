import 'package:flutter/material.dart';

class WithdrawalSettingsCard extends StatelessWidget {
  final TextEditingController minPayoutController;
  final TextEditingController minPulsaWithdrawalController;
  final List<int> allowedWithdrawalDays;
  final ValueChanged<int> onDayToggle;

  const WithdrawalSettingsCard({
    super.key,
    required this.minPayoutController,
    required this.minPulsaWithdrawalController,
    required this.allowedWithdrawalDays,
    required this.onDayToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: minPayoutController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Min. Penarikan Bank',
              prefixText: 'Rp ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: minPulsaWithdrawalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Min. Klaim Pulsa',
              prefixText: 'Rp ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Jadwal Penarikan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final itemSize = (width - (6 * 8)) / 7;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final dayName = ['S', 'S', 'R', 'K', 'J', 'S', 'M'][index];
                  final isSelected = allowedWithdrawalDays.contains(day);
                  return GestureDetector(
                    onTap: () => onDayToggle(day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: itemSize,
                      height: itemSize,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          dayName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
