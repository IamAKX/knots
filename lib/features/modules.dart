import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fmt.dart';
import '../data/store.dart';

enum FT { text, multiline, number, money, select, date, bool, side }

class Field {
  const Field(
    this.key,
    this.label,
    this.type, {
    this.options = const [],
    this.req = false,
    this.def,
  });
  final String key;
  final String label;
  final FT type;
  final List<String> options;
  final bool req;
  final dynamic def;
}

class Stat {
  const Stat(this.label, this.value, this.icon, [this.color]);
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
}

class Badge {
  const Badge(this.text, this.color);
  final String text;
  final Color color;
}

/// Declarative description of one CRUD section. The generic ModuleScreen renders it.
class Module {
  const Module({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.col,
    required this.fields,
    required this.title_,
    required this.sub,
    this.trailing,
    this.badge,
    this.stats,
    this.filterKey,
    this.filterOptions = const [],
    this.toggleKey,
    this.toggleOn,
    this.toggleOff,
    this.addLabel = 'Add',
    this.emptyText = 'Tap the button to add your first one.',
    this.hasSide = true,
  });
  final String id, title, subtitle, col, addLabel, emptyText;
  final IconData icon;
  final List<Field> fields;
  final String Function(Rec) title_;
  final String Function(Rec) sub;
  final String Function(Rec)? trailing;
  final Badge? Function(Rec)? badge;
  final List<Stat> Function(WidgetRef, List<Rec>)? stats;
  final String? filterKey;
  final List<String> filterOptions;
  // Quick check-off (tasks / shopping). toggleOn/Off are values stored in toggleKey.
  final String? toggleKey;
  final dynamic toggleOn, toggleOff;
  final bool hasSide;

  bool isDone(Rec r) => toggleKey != null && r.d[toggleKey] == toggleOn;
}

const categories = [
  'Venue',
  'Catering',
  'Decor',
  'Photography',
  'Attire',
  'Jewellery',
  'Makeup',
  'Music & DJ',
  'Invitations',
  'Travel',
  'Transport',
  'Rituals',
  'Gifts & Favours',
  'Misc',
];
const events = [
  'Engagement',
  'Mehendi',
  'Haldi',
  'Sangeet',
  'Wedding',
  'Reception',
];

Color statusColor(String s) => switch (s) {
  'Paid' || 'Done' || 'Confirmed' || 'Booked' => const Color(0xFF4E9A6B),
  'Partial' ||
  'In progress' ||
  'Invited' ||
  'Shortlisted' => const Color(0xFFD19A3F),
  'Declined' => const Color(0xFFC0443C),
  'Pending' || 'To do' || 'Not invited' => const Color(0xFF8B8680),
  _ => const Color(0xFF8B8680),
};

double _sum(Iterable<Rec> l, String k) => l.fold(0.0, (a, r) => a + r.n(k));

final expenses = Module(
  id: 'expenses',
  title: 'Expenses',
  subtitle: 'Every rupee, tagged to a side',
  icon: Icons.receipt_long_rounded,
  col: 'expenses',
  addLabel: 'Add expense',
  emptyText: 'Log your first payment to start tracking spending.',
  fields: const [
    Field('title', 'What was it for?', FT.text, req: true),
    Field('amount', 'Total amount', FT.money, req: true),
    Field('paid', 'Amount paid so far', FT.money),
    Field('category', 'Category', FT.select, options: categories, def: 'Misc'),
    Field('side', 'Paid by', FT.side),
    Field(
      'status',
      'Status',
      FT.select,
      options: ['Paid', 'Partial', 'Pending'],
      def: 'Paid',
    ),
    Field('date', 'Date', FT.date),
    Field(
      'mode',
      'Payment mode',
      FT.select,
      options: ['UPI', 'Cash', 'Card', 'Bank'],
    ),
    Field('vendor', 'Vendor', FT.text),
    Field('notes', 'Notes', FT.multiline),
  ],
  title_: (r) => r.s('title'),
  sub: (r) => [
    r.s('category'),
    if (r.dt('date') != null) dateShort(r.dt('date')!),
  ].where((e) => e.isNotEmpty).join(' · '),
  trailing: (r) => money(r.n('amount')),
  badge: (r) => r.s('status').isEmpty
      ? null
      : Badge(r.s('status'), statusColor(r.s('status'))),
  filterKey: 'status',
  filterOptions: const ['Paid', 'Partial', 'Pending'],
  stats: (ref, l) => [
    Stat(
      'Total',
      moneyShort(_sum(l, 'amount')),
      Icons.account_balance_wallet_rounded,
    ),
    Stat(
      'Paid',
      moneyShort(_sum(l, 'paid')),
      Icons.check_circle_rounded,
      const Color(0xFF4E9A6B),
    ),
    Stat(
      'Balance due',
      moneyShort(_sum(l, 'amount') - _sum(l, 'paid')),
      Icons.schedule_rounded,
      const Color(0xFFD19A3F),
    ),
  ],
);

final tasks = Module(
  id: 'tasks',
  title: 'To-do',
  subtitle: 'What needs doing, and by whom',
  icon: Icons.checklist_rounded,
  col: 'tasks',
  addLabel: 'Add task',
  emptyText: 'Add the first thing on your list.',
  toggleKey: 'status',
  toggleOn: 'Done',
  toggleOff: 'To do',
  fields: const [
    Field('title', 'Task', FT.text, req: true),
    Field('details', 'Details', FT.multiline),
    Field('side', 'Who is responsible?', FT.side),
    Field('due', 'Due date', FT.date),
    Field(
      'priority',
      'Priority',
      FT.select,
      options: ['Low', 'Medium', 'High'],
      def: 'Medium',
    ),
    Field(
      'status',
      'Status',
      FT.select,
      options: ['To do', 'In progress', 'Done'],
      def: 'To do',
    ),
    Field('category', 'Category', FT.select, options: categories, def: 'Misc'),
    Field('event', 'Event', FT.select, options: events, def: 'Wedding'),
  ],
  title_: (r) => r.s('title'),
  sub: (r) {
    final d = r.dt('due');
    return [
      if (d != null) 'Due ${dateShort(d)}',
      r.s('category'),
    ].where((e) => e.isNotEmpty).join(' · ');
  },
  badge: (r) {
    final d = r.dt('due');
    if (r.s('status') != 'Done' &&
        d != null &&
        d.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return const Badge('Overdue', Color(0xFFC0443C));
    }
    return r.s('priority') == 'High'
        ? const Badge('High', Color(0xFFB5546A))
        : null;
  },
  filterKey: 'status',
  filterOptions: const ['To do', 'In progress', 'Done'],
  stats: (ref, l) {
    final done = l.where((r) => r.s('status') == 'Done').length;
    final od = l
        .where(
          (r) =>
              r.s('status') != 'Done' &&
              r.dt('due') != null &&
              r.dt('due')!.isBefore(DateTime.now()),
        )
        .length;
    return [
      Stat('Total tasks', '${l.length}', Icons.list_alt_rounded),
      Stat(
        'Completed',
        '$done',
        Icons.task_alt_rounded,
        const Color(0xFF4E9A6B),
      ),
      Stat(
        'Overdue',
        '$od',
        Icons.warning_amber_rounded,
        const Color(0xFFC0443C),
      ),
    ];
  },
);

final purchases = Module(
  id: 'shopping',
  title: 'Shopping',
  subtitle: 'Things to buy, with estimates',
  icon: Icons.shopping_bag_rounded,
  col: 'purchases',
  addLabel: 'Add item',
  emptyText: 'List what you need to buy.',
  toggleKey: 'purchased',
  toggleOn: true,
  toggleOff: false,
  fields: const [
    Field('item', 'Item', FT.text, req: true),
    Field('category', 'Category', FT.select, options: categories, def: 'Misc'),
    Field('qty', 'Quantity', FT.number, def: 1),
    Field('estimate', 'Estimated price', FT.money),
    Field('actual', 'Actual price', FT.money),
    Field('store', 'Store / vendor', FT.text),
    Field('side', 'Buying side', FT.side),
    Field(
      'priority',
      'Priority',
      FT.select,
      options: ['Low', 'Medium', 'High'],
      def: 'Medium',
    ),
    Field('purchased', 'Already purchased', FT.bool),
  ],
  title_: (r) => r.s('item'),
  sub: (r) => [
    r.s('category'),
    if (r.n('qty') > 1) '× ${r.n('qty').round()}',
  ].where((e) => e.isNotEmpty).join(' · '),
  trailing: (r) => money(r.n('actual') > 0 ? r.n('actual') : r.n('estimate')),
  badge: (r) =>
      r.b('purchased') ? const Badge('Bought', Color(0xFF4E9A6B)) : null,
  stats: (ref, l) => [
    Stat('Estimated', moneyShort(_sum(l, 'estimate')), Icons.calculate_rounded),
    Stat(
      'Spent',
      moneyShort(_sum(l, 'actual')),
      Icons.payments_rounded,
      const Color(0xFF4E9A6B),
    ),
    Stat(
      'Bought',
      '${l.where((r) => r.b('purchased')).length}/${l.length}',
      Icons.inventory_2_rounded,
    ),
  ],
);

final guests = Module(
  id: 'guests',
  title: 'Guests',
  subtitle: 'Invitations, RSVPs and headcount',
  icon: Icons.groups_rounded,
  col: 'guests',
  addLabel: 'Add guest',
  emptyText: 'Add your first guest or family.',
  fields: const [
    Field('name', 'Name / family', FT.text, req: true),
    Field('side', 'Invited by', FT.side),
    Field(
      'relation',
      'Relation',
      FT.select,
      options: ['Family', 'Friend', 'Colleague', 'Other'],
      def: 'Family',
    ),
    Field(
      'status',
      'Invitation status',
      FT.select,
      options: ['Not invited', 'Invited', 'Confirmed', 'Declined'],
      def: 'Not invited',
    ),
    Field('adults', 'Adults', FT.number, def: 1),
    Field('kids', 'Kids', FT.number, def: 0),
    Field('group', 'Group / household', FT.text),
    Field('phone', 'Phone', FT.text),
    Field('email', 'Email', FT.text),
    Field('city', 'City', FT.text),
    Field('events', 'Events invited to', FT.text),
    Field(
      'diet',
      'Diet',
      FT.select,
      options: ['Veg', 'Non-veg', 'Jain', 'Other'],
      def: 'Veg',
    ),
    Field('stay', 'Needs accommodation', FT.bool),
    Field('table', 'Table / seat', FT.text),
    Field('notes', 'Notes', FT.multiline),
  ],
  title_: (r) => r.s('name'),
  sub: (r) {
    final n = r.n('adults').round() + r.n('kids').round();
    return [
      r.s('relation'),
      '$n ${n == 1 ? 'person' : 'people'}',
      r.s('city'),
    ].where((e) => e.isNotEmpty).join(' · ');
  },
  badge: (r) => r.s('status').isEmpty
      ? null
      : Badge(r.s('status'), statusColor(r.s('status'))),
  filterKey: 'status',
  filterOptions: const ['Not invited', 'Invited', 'Confirmed', 'Declined'],
  stats: (ref, l) {
    int head(Iterable<Rec> x) =>
        x.fold(0, (a, r) => a + r.n('adults').round() + r.n('kids').round());
    return [
      Stat('Headcount', '${head(l)}', Icons.people_alt_rounded),
      Stat(
        'Confirmed',
        '${head(l.where((r) => r.s('status') == 'Confirmed'))}',
        Icons.how_to_reg_rounded,
        const Color(0xFF4E9A6B),
      ),
      Stat(
        'Awaiting reply',
        '${head(l.where((r) => r.s('status') == 'Invited'))}',
        Icons.mark_email_unread_rounded,
        const Color(0xFFD19A3F),
      ),
    ];
  },
);

final menu = Module(
  id: 'food',
  title: 'Food & menu',
  subtitle: 'Dishes, per-plate cost and catering estimate',
  icon: Icons.restaurant_rounded,
  col: 'menu',
  addLabel: 'Add dish',
  hasSide: false,
  emptyText: 'Start building the menu.',
  toggleKey: 'approved',
  toggleOn: true,
  toggleOff: false,
  fields: const [
    Field('dish', 'Dish', FT.text, req: true),
    Field(
      'course',
      'Course',
      FT.select,
      options: ['Starter', 'Main', 'Dessert', 'Beverage'],
      def: 'Main',
    ),
    Field('diet', 'Diet', FT.select, options: ['Veg', 'Non-veg'], def: 'Veg'),
    Field('event', 'Event', FT.select, options: events, def: 'Wedding'),
    Field('costPerPlate', 'Cost per plate', FT.money),
    Field('caterer', 'Caterer', FT.text),
    Field('approved', 'Final approved', FT.bool),
    Field('notes', 'Tasting notes', FT.multiline),
  ],
  title_: (r) => r.s('dish'),
  sub: (r) => [
    r.s('course'),
    r.s('diet'),
    r.s('event'),
  ].where((e) => e.isNotEmpty).join(' · '),
  trailing: (r) => '${money(r.n('costPerPlate'))}/plate',
  badge: (r) =>
      r.b('approved') ? const Badge('Approved', Color(0xFF4E9A6B)) : null,
  stats: (ref, l) {
    final plate = _sum(l.where((r) => r.b('approved')), 'costPerPlate');
    final g = listOf(ref, 'guests').where((r) => r.s('status') == 'Confirmed');
    final heads = g.fold(
      0,
      (a, r) => a + r.n('adults').round() + r.n('kids').round(),
    );
    return [
      Stat('Approved / plate', moneyShort(plate), Icons.dinner_dining_rounded),
      Stat('Confirmed guests', '$heads', Icons.people_alt_rounded),
      Stat(
        'Catering estimate',
        moneyShort(plate * heads),
        Icons.payments_rounded,
        const Color(0xFFC06C52),
      ),
    ];
  },
);

final gifts = Module(
  id: 'gifts',
  title: 'Gifts',
  subtitle: 'Who gave what, and who to thank',
  icon: Icons.card_giftcard_rounded,
  col: 'gifts',
  addLabel: 'Add gift',
  emptyText: 'Record the first gift you receive.',
  toggleKey: 'thanked',
  toggleOn: true,
  toggleOff: false,
  fields: const [
    Field('giver', 'Given by', FT.text, req: true),
    Field('side', 'Whose guest?', FT.side),
    Field(
      'type',
      'Type',
      FT.select,
      options: ['Cash', 'Gold', 'Item', 'Voucher'],
      def: 'Cash',
    ),
    Field('value', 'Amount / value', FT.money),
    Field('description', 'Description', FT.text),
    Field(
      'relation',
      'Relation',
      FT.select,
      options: ['Family', 'Friend', 'Colleague', 'Other'],
    ),
    Field('event', 'Event', FT.select, options: events, def: 'Wedding'),
    Field('date', 'Date received', FT.date),
    Field('thanked', 'Thank-you sent', FT.bool),
    Field('returnGift', 'Return gift due', FT.bool),
  ],
  title_: (r) => r.s('giver'),
  sub: (r) => [
    r.s('type'),
    r.s('description'),
    r.s('event'),
  ].where((e) => e.isNotEmpty).join(' · '),
  trailing: (r) => money(r.n('value')),
  badge: (r) => r.b('thanked')
      ? const Badge('Thanked', Color(0xFF4E9A6B))
      : (r.b('returnGift')
            ? const Badge('Return gift', Color(0xFFB5546A))
            : null),
  filterKey: 'type',
  filterOptions: const ['Cash', 'Gold', 'Item', 'Voucher'],
  stats: (ref, l) => [
    Stat(
      'Total value',
      moneyShort(_sum(l, 'value')),
      Icons.card_giftcard_rounded,
    ),
    Stat('Gifts received', '${l.length}', Icons.redeem_rounded),
    Stat(
      'To thank',
      '${l.where((r) => !r.b('thanked')).length}',
      Icons.favorite_border_rounded,
      const Color(0xFFB5546A),
    ),
  ],
);

final vendors = Module(
  id: 'vendors',
  title: 'Vendors',
  subtitle: 'Quotes, advances and balances',
  icon: Icons.storefront_rounded,
  col: 'vendors',
  addLabel: 'Add vendor',
  emptyText: 'Shortlist your first vendor.',
  fields: const [
    Field('name', 'Vendor name', FT.text, req: true),
    Field('category', 'Category', FT.select, options: categories, def: 'Misc'),
    Field(
      'status',
      'Status',
      FT.select,
      options: ['Shortlisted', 'Booked', 'Paid'],
      def: 'Shortlisted',
    ),
    Field('quote', 'Quote', FT.money),
    Field('advance', 'Advance paid', FT.money),
    Field('due', 'Balance due on', FT.date),
    Field('side', 'Managed by', FT.side),
    Field('phone', 'Phone', FT.text),
    Field('rating', 'Rating (1–5)', FT.number),
    Field('notes', 'Notes', FT.multiline),
  ],
  title_: (r) => r.s('name'),
  sub: (r) => [
    r.s('category'),
    'Balance ${moneyShort(r.n('quote') - r.n('advance'))}',
  ].where((e) => e.isNotEmpty).join(' · '),
  trailing: (r) => money(r.n('quote')),
  badge: (r) => r.s('status').isEmpty
      ? null
      : Badge(r.s('status'), statusColor(r.s('status'))),
  filterKey: 'status',
  filterOptions: const ['Shortlisted', 'Booked', 'Paid'],
  stats: (ref, l) => [
    Stat(
      'Total quotes',
      moneyShort(_sum(l, 'quote')),
      Icons.request_quote_rounded,
    ),
    Stat(
      'Advances paid',
      moneyShort(_sum(l, 'advance')),
      Icons.check_circle_rounded,
      const Color(0xFF4E9A6B),
    ),
    Stat(
      'Balance',
      moneyShort(_sum(l, 'quote') - _sum(l, 'advance')),
      Icons.schedule_rounded,
      const Color(0xFFD19A3F),
    ),
  ],
);

final budgetLines = Module(
  id: 'budget',
  title: 'Budget',
  subtitle: 'Planned vs actual by category',
  icon: Icons.pie_chart_rounded,
  col: 'budget',
  addLabel: 'Add category',
  fields: const [
    Field(
      'category',
      'Category',
      FT.select,
      options: categories,
      req: true,
      def: 'Venue',
    ),
    Field('planned', 'Planned budget', FT.money, req: true),
    Field('groomShare', 'Groom side share (%)', FT.number, def: 50),
    Field('side', 'Mostly handled by', FT.side),
  ],
  title_: (r) => r.s('category'),
  sub: (r) => '',
);

final allModules = [expenses, tasks, purchases, guests, menu, gifts, vendors];
