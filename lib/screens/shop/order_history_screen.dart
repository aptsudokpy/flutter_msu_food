import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/food_order.dart';
import '../../services/db.dart';

enum _HistoryPeriod { day, week, month, custom }

class OrderHistoryScreen extends StatefulWidget {
  final String shopId;

  const OrderHistoryScreen({super.key, required this.shopId});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  _HistoryPeriod _period = _HistoryPeriod.day;
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  DateTimeRange? _customRange;

  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final _numberFormat = NumberFormat('#,##0.##', 'th_TH');

  (DateTime, DateTime) get _range {
    switch (_period) {
      case _HistoryPeriod.day:
        final start = DateUtils.dateOnly(_selectedDate);
        return (start, start.add(const Duration(days: 1)));
      case _HistoryPeriod.week:
        final date = DateUtils.dateOnly(_selectedDate);
        final start = date.subtract(Duration(days: date.weekday - 1));
        return (start, start.add(const Duration(days: 7)));
      case _HistoryPeriod.month:
        final start = DateTime(_selectedDate.year, _selectedDate.month);
        return (start, DateTime(_selectedDate.year, _selectedDate.month + 1));
      case _HistoryPeriod.custom:
        final range = _customRange;
        if (range == null) {
          final start = DateUtils.dateOnly(_selectedDate);
          return (start, start.add(const Duration(days: 1)));
        }
        final start = DateUtils.dateOnly(range.start);
        final end = DateUtils.dateOnly(range.end).add(const Duration(days: 1));
        return (start, end);
    }
  }

  String get _rangeLabel {
    final (start, exclusiveEnd) = _range;
    final end = exclusiveEnd.subtract(const Duration(days: 1));
    if (start == end) return _dateFormat.format(start);
    return '${_dateFormat.format(start)} - ${_dateFormat.format(end)}';
  }

  Future<void> _selectCustomRange() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final initialStart = _customRange?.start ?? now;
    final initialEnd = _customRange?.end ?? now;
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: initialStart.isAfter(now) ? now : initialStart,
        end: initialEnd.isAfter(now) ? now : initialEnd,
      ),
      helpText: 'เลือกช่วงวันที่ของประวัติออร์เดอร์',
      saveText: 'แสดงประวัติ',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _customRange = selected;
      _period = _HistoryPeriod.custom;
    });
  }

  void _selectPeriod(_HistoryPeriod period) {
    if (period == _HistoryPeriod.custom) {
      _selectCustomRange();
      return;
    }
    setState(() {
      _period = period;
      _selectedDate = DateUtils.dateOnly(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final (start, end) = _range;
    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติออร์เดอร์')),
      body: StreamBuilder<List<FoodOrder>>(
        stream: Db().watchCompletedShopOrders(widget.shopId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('ผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.where((order) {
            final completedAt = order.updatedAt ?? order.createdAt;
            return completedAt != null &&
                !completedAt.isBefore(start) &&
                completedAt.isBefore(end);
          }).toList()
            ..sort((first, second) {
              final firstDate = first.updatedAt ?? first.createdAt!;
              final secondDate = second.updatedAt ?? second.createdAt!;
              return secondDate.compareTo(firstDate);
            });
          final income = orders.fold<num>(0, (sum, order) => sum + order.total);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<_HistoryPeriod>(
                  segments: const [
                    ButtonSegment(
                      value: _HistoryPeriod.day,
                      label: Text('รายวัน'),
                    ),
                    ButtonSegment(
                      value: _HistoryPeriod.week,
                      label: Text('รายสัปดาห์'),
                    ),
                    ButtonSegment(
                      value: _HistoryPeriod.month,
                      label: Text('รายเดือน'),
                    ),
                    ButtonSegment(
                      value: _HistoryPeriod.custom,
                      label: Text('เลือกวันที่'),
                    ),
                  ],
                  selected: {_period},
                  onSelectionChanged: (selection) =>
                      _selectPeriod(selection.first),
                  showSelectedIcon: false,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: InkWell(
                  onTap: _selectCustomRange,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ช่วงวันที่',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _rangeLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_calendar_outlined, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payments_outlined),
                          const SizedBox(width: 8),
                          Text(
                            'ยอดรวมออร์เดอร์สำเร็จ',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_numberFormat.format(income)} บาท',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text('สำเร็จ ${orders.length} ออร์เดอร์ในช่วงเวลานี้'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'รายการออร์เดอร์',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (orders.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 10),
                      const Text('ไม่พบออร์เดอร์สำเร็จในช่วงวันที่นี้'),
                    ],
                  ),
                )
              else
                for (final order in orders)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFE7F6EF),
                            child: Icon(
                              Icons.check_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _dateTimeFormat.format(
                                    order.updatedAt ?? order.createdAt!,
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  order.items
                                      .map((item) => '${item.name} ×${item.qty}')
                                      .join(', '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_numberFormat.format(order.total)} บาท',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}