import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';

class DebtManagementScreen extends StatefulWidget {
  const DebtManagementScreen({super.key});

  @override
  State<DebtManagementScreen> createState() => _DebtManagementScreenState();
}

class _DebtManagementScreenState extends State<DebtManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.debtManagementTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: localizations.debtYouOwe),
            Tab(text: localizations.debtOwedToYou),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Debts You Owe tab
          _DebtList(type: TransactionType.debtYouOwe),
          
          // Debts Owed to You tab
          _DebtList(type: TransactionType.debtOwedToYou),
        ],
      ),
    );
  }
}

class _DebtList extends StatefulWidget {
  final TransactionType type;
  
  const _DebtList({required this.type});

  @override
  State<_DebtList> createState() => _DebtListState();
}

class _DebtListState extends State<_DebtList> {
  Future<void> _markAsPaid(Transaction debt) async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    
    final updatedDebt = debt.copyWith(isPaid: true);
    await databaseService.updateTransaction(updatedDebt);
    
    setState(() {});
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.debtMarkedAsPaid),
        ),
      );
    }
  }
  
  Future<void> _deleteDebt(Transaction debt) async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    
    await databaseService.deleteTransaction(debt.id!);
    
    setState(() {});
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.transactionDeleted),
        ),
      );
    }
  }
  
  Future<void> _editDebt(Transaction debt) async {
    // Navigate to edit screen or show edit dialog
    final result = await showDialog<Transaction>(
      context: context,
      builder: (context) => _EditDebtDialog(debt: debt),
    );
    
    if (result != null) {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      await databaseService.updateTransaction(result);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    
    return FutureBuilder<List<Transaction>>(
      future: databaseService.getTransactionsByType(widget.type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(localizations.noDebts));
        }
        
        final debts = snapshot.data!;
        
        return FutureBuilder<String>(
          future: settingsService.getCurrencySymbol(),
          builder: (context, currencySnapshot) {
            final currencySymbol = currencySnapshot.data ?? '\$';
            
            return ListView.builder(
              itemCount: debts.length,
              itemBuilder: (context, index) {
                final debt = debts[index];
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                debt.description,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              '$currencySymbol ${debt.amount.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              DateFormat.yMMMd().format(debt.date),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const Spacer(),
                            Chip(
                              label: Text(
                                debt.isPaid ? localizations.paid : localizations.unpaid,
                              ),
                              backgroundColor: debt.isPaid ? Colors.green.shade100 : Colors.orange.shade100,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!debt.isPaid)
                              TextButton.icon(
                                onPressed: () => _markAsPaid(debt),
                                icon: const Icon(Icons.check),
                                label: Text(localizations.markAsPaid),
                              ),
                            TextButton.icon(
                              onPressed: () => _editDebt(debt),
                              icon: const Icon(Icons.edit),
                              label: Text(localizations.edit),
                            ),
                            TextButton.icon(
                              onPressed: () => _deleteDebt(debt),
                              icon: const Icon(Icons.delete),
                              label: Text(localizations.delete),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _EditDebtDialog extends StatefulWidget {
  final Transaction debt;
  
  const _EditDebtDialog({required this.debt});

  @override
  State<_EditDebtDialog> createState() => _EditDebtDialogState();
}

class _EditDebtDialogState extends State<_EditDebtDialog> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _date;
  late bool _isPaid;
  
  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.debt.amount.toString());
    _descriptionController = TextEditingController(text: widget.debt.description);
    _date = widget.debt.date;
    _isPaid = widget.debt.isPaid;
  }
  
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    
    return AlertDialog(
      title: Text(localizations.edit),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: localizations.description,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('${localizations.date}: ${DateFormat.yMMMd().format(_date)}'),
                const Spacer(),
                IconButton(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(localizations.debtStatus),
                const Spacer(),
                Switch(
                  value: _isPaid,
                  onChanged: (value) {
                    setState(() {
                      _isPaid = value;
                    });
                  },
                ),
                Text(_isPaid ? localizations.paid : localizations.unpaid),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () {
            final updatedDebt = widget.debt.copyWith(
              amount: double.tryParse(_amountController.text) ?? widget.debt.amount,
              description: _descriptionController.text,
              date: _date,
              isPaid: _isPaid,
            );
            Navigator.of(context).pop(updatedDebt);
          },
          child: Text(MaterialLocalizations.of(context).saveButtonLabel),
        ),
      ],
    );
  }
}