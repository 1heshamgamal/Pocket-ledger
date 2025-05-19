import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';

class TransactionEntryScreen extends StatefulWidget {
  const TransactionEntryScreen({super.key});

  @override
  State<TransactionEntryScreen> createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends State<TransactionEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  TransactionType _type = TransactionType.expense;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _date = DateTime.now();
  
  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }
  
  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      
      final transaction = Transaction(
        type: _type,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text,
        date: _date,
        isPaid: false, // New transactions are unpaid by default
      );
      
      await databaseService.insertTransaction(transaction);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.transactionSaved),
          ),
        );
        
        // Clear form
        _amountController.clear();
        _descriptionController.clear();
        setState(() {
          _date = DateTime.now();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.transactionEntryTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Transaction Type
              Text(
                localizations.transactionType,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SegmentedButton<TransactionType>(
                segments: [
                  ButtonSegment<TransactionType>(
                    value: TransactionType.expense,
                    label: Text(localizations.expense),
                    icon: const Icon(Icons.money_off),
                  ),
                  ButtonSegment<TransactionType>(
                    value: TransactionType.debtYouOwe,
                    label: Text(localizations.debtYouOwe),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment<TransactionType>(
                    value: TransactionType.debtOwedToYou,
                    label: Text(localizations.debtOwedToYou),
                    icon: const Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _type = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Amount
              FutureBuilder<String>(
                future: settingsService.getCurrencySymbol(),
                builder: (context, snapshot) {
                  final currencySymbol = snapshot.data ?? '\$';
                  
                  return TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: localizations.amount,
                      prefixText: currencySymbol,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.enterAmount;
                      }
                      if (double.tryParse(value) == null) {
                        return localizations.enterAmount;
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: localizations.description,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.enterDescription;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Date
              Row(
                children: [
                  Text(
                    '${localizations.date}: ${DateFormat.yMMMd().format(_date)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => _selectDate(context),
                    child: const Icon(Icons.calendar_today),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Save Button
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(localizations.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}