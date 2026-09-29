import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:dashboard_desginland/model/product_model.dart';
import '../../../../Core/Utils/app.colors.dart';

class DiscountDialog extends StatefulWidget {
  final ProductModel product;
  final CollectionReference productsRef;

  const DiscountDialog({
    super.key,
    required this.product,
    required this.productsRef,
  });

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  late TextEditingController _discountController;
  late DateTime _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _discountController = TextEditingController(
      text: widget.product.discountPercentage > 0 ? widget.product.discountPercentage.toString() : '',
    );
    _selectedDate = widget.product.discountUntil ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.local_offer, color: AppColors.primaryPurple),
          const SizedBox(width: 8),
          Text(
            "Set Temporary Discount",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _discountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              labelText: "Discount Percentage (%)",
              hintText: "e.g. 15 for 15%",
              prefixIcon: const Icon(Icons.percent, color: AppColors.primaryPurple),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_month, color: AppColors.primaryPurple),
            title: Text(
              "Discount Valid Until:",
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            subtitle: Text(
              "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} - ${_selectedDate.hour}:${_selectedDate.minute.toString().padLeft(2, '0')}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : AppColors.textDark,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit_calendar),
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (pickedDate != null) {
                  if (!mounted) return;
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_selectedDate),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _selectedDate = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                    });
                  }
                }
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
          onPressed: _isSaving
              ? null
              : () async {
            final percent = int.tryParse(_discountController.text.trim()) ?? 0;
            if (percent <= 0 || percent > 100) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please enter a valid percentage (1-100)")),
              );
              return;
            }

            setState(() => _isSaving = true);

            final discountData = {
              'discountPercentage': percent,
              'discountUntil': Timestamp.fromDate(_selectedDate),
            };

            try {
              await widget.productsRef.doc(widget.product.doc).update(discountData);

              if (!mounted) return;

              final updatedProduct = ProductModel(
                doc: widget.product.doc,
                title: widget.product.title,
                price: widget.product.price,
                avgRate: widget.product.avgRate,
                categoryDoc: widget.product.categoryDoc,
                description: widget.product.description,
                images: widget.product.images,
                SubCategoryDoc: widget.product.SubCategoryDoc,
                discountPercentage: percent.toDouble(),
                discountUntil: _selectedDate,
                isActive: widget.product.isActive,
              );

              Navigator.pop(context, updatedProduct);
            } catch (e) {
              setState(() => _isSaving = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed to apply discount: $e")),
                );
              }
            }
          },
          child: _isSaving
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
              : const Text("Apply Discount", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}