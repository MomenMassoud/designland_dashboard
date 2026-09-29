import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../controller/order_detail_controller.dart';

class AddTransactionDialog extends StatefulWidget {
  final bool isExpense;
  final bool isDark;
  final OrderDetailController controller;

  const AddTransactionDialog({
    super.key,
    required this.isExpense,
    required this.isDark,
    required this.controller,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogBgColor = widget.isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final dialogTextColor = widget.isDark ? Colors.white : AppColors.textDark;
    final hintColor = widget.isDark ? Colors.grey[400] : Colors.grey[600];
    final inputFillColor = widget.isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8FAFC);
    final borderColor = widget.isDark ? Colors.grey.shade700 : const Color(0xFFE2E8F0);

    return AlertDialog(
      backgroundColor: dialogBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.isExpense ? "Record New Expense".tr : "Record New Payment Deposit".tr,
        style: TextStyle(color: dialogTextColor, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: dialogTextColor),
            decoration: InputDecoration(
              labelText: widget.isExpense ? "Expense Amount (\$) *" : "Amount Paid (\$) *".tr,
              labelStyle: TextStyle(color: hintColor),
              filled: true,
              fillColor: inputFillColor,
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor)),
              focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: AppColors.primaryPurple, width: 1.5)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            style: TextStyle(color: dialogTextColor),
            decoration: InputDecoration(
              labelText: widget.isExpense
                  ? "Notes (e.g. Shipping, Printing, Packaging)".tr
                  : "Notes (e.g. Bank Transfer, Instapay, Cash)".tr,
              labelStyle: TextStyle(color: hintColor),
              filled: true,
              fillColor: inputFillColor,
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor)),
              focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: AppColors.primaryPurple, width: 1.5)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text("Cancel".tr,
              style: TextStyle(color: widget.isDark ? Colors.grey[400] : Colors.grey[700])),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isExpense ? Colors.orange.shade800 : AppColors.primaryPurple,
          ),
          onPressed: _isSaving
              ? null
              : () async {
            final double? amount = double.tryParse(_amountController.text);
            if (amount != null && amount > 0) {
              setState(() => _isSaving = true);
              final success = await widget.controller.addTransaction(
                isExpense: widget.isExpense,
                amount: amount,
                notes: _notesController.text,
              );
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "${widget.isExpense ? 'Expense'.tr : 'Payment'.tr} ${"recorded successfully!".tr}",
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            }
          },
          child: _isSaving
              ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text("Save Transaction".tr, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}