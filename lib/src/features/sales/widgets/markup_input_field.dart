import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markating_kbm_app/src/core/utils/currency_input_formatter.dart';

class MarkupInputField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final int quantity; // To calculate total markup prediction

  const MarkupInputField({
    super.key,
    required this.controller,
    this.onChanged,
    this.quantity = 1,
  });

  @override
  State<MarkupInputField> createState() => _MarkupInputFieldState();
}

class _MarkupInputFieldState extends State<MarkupInputField> {
  @override
  void initState() {
    super.initState();
    // Rebuild when text changes to update total calculation
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total markup for preview
    int markupPerItem = 0;
    String cleanText = widget.controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isNotEmpty) {
      markupPerItem = int.parse(cleanText);
    }
    int totalEstimated = markupPerItem * widget.quantity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            labelText: 'Markup Harga (Per Item)',
            hintText: '0',
            prefixIcon: const Icon(Icons.show_chart, color: Colors.green),
            suffixText: '/ item',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).cardColor,
          ),
        ),
        if (markupPerItem > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    children: [
                      const TextSpan(text: 'Total keuntungan markup: '),
                      TextSpan(
                        text: CurrencyInputFormatter.formatRupiah(
                          totalEstimated,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      TextSpan(text: ' (${widget.quantity} item)'),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
