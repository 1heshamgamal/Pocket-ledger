import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../services/database_service.dart';
import '../services/settings_service.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  
  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear, _selectedMonth, 1),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    
    if (picked != null) {
      setState(() {
        _selectedMonth = picked.month;
        _selectedYear = picked.year;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.monthlyReportTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _selectMonth(context),
            tooltip: 'Select Month',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<String>(
          future: settingsService.getCurrencySymbol(),
          builder: (context, currencySnapshot) {
            final currencySymbol = currencySnapshot.data ?? '\$';
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month and Year display
                Center(
                  child: Text(
                    DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth, 1)),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Financial summary
                FutureBuilder<List<double>>(
                  future: Future.wait([
                    databaseService.getTotalExpensesForMonth(_selectedMonth, _selectedYear),
                    databaseService.getTotalDebtsYouOweForMonth(_selectedMonth, _selectedYear),
                    databaseService.getTotalDebtsOwedToYouForMonth(_selectedMonth, _selectedYear),
                    databaseService.getNetBalanceForMonth(_selectedMonth, _selectedYear),
                  ]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (!snapshot.hasData) {
                      return Center(child: Text(localizations.noTransactions));
                    }
                    
                    final totalExpenses = snapshot.data![0];
                    final totalDebtsYouOwe = snapshot.data![1];
                    final totalDebtsOwedToYou = snapshot.data![2];
                    final netBalance = snapshot.data![3];
                    
                    return Column(
                      children: [
                        // Summary cards
                        _buildSummaryCard(
                          context,
                          localizations.totalExpenses,
                          '$currencySymbol ${totalExpenses.toStringAsFixed(2)}',
                          Colors.red,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryCard(
                          context,
                          localizations.totalDebtsYouOwe,
                          '$currencySymbol ${totalDebtsYouOwe.toStringAsFixed(2)}',
                          Colors.orange,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryCard(
                          context,
                          localizations.totalDebtsOwedToYou,
                          '$currencySymbol ${totalDebtsOwedToYou.toStringAsFixed(2)}',
                          Colors.green,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryCard(
                          context,
                          localizations.netBalance,
                          '$currencySymbol ${netBalance.toStringAsFixed(2)}',
                          netBalance >= 0 ? Colors.blue : Colors.red,
                        ),
                        const SizedBox(height: 32),
                        
                        // Chart
                        if (totalExpenses > 0 || totalDebtsYouOwe > 0 || totalDebtsOwedToYou > 0)
                          Expanded(
                            child: _buildPieChart(
                              totalExpenses,
                              totalDebtsYouOwe,
                              totalDebtsOwedToYou,
                              localizations,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPieChart(
    double expenses,
    double debtsYouOwe,
    double debtsOwedToYou,
    AppLocalizations localizations,
  ) {
    return Column(
      children: [
        Text(
          'Breakdown',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: PieChart(
            PieChartData(
              sections: [
                if (expenses > 0)
                  PieChartSectionData(
                    value: expenses,
                    title: localizations.expense,
                    color: Colors.red,
                    radius: 100,
                  ),
                if (debtsYouOwe > 0)
                  PieChartSectionData(
                    value: debtsYouOwe,
                    title: localizations.debtYouOwe,
                    color: Colors.orange,
                    radius: 100,
                  ),
                if (debtsOwedToYou > 0)
                  PieChartSectionData(
                    value: debtsOwedToYou,
                    title: localizations.debtOwedToYou,
                    color: Colors.green,
                    radius: 100,
                  ),
              ],
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(Colors.red, localizations.expense),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.orange, localizations.debtYouOwe),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.green, localizations.debtOwedToYou),
          ],
        ),
      ],
    );
  }
  
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}