import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/db.dart';
import 'customer/shop_list_screen.dart';
import 'shop/order_board_screen.dart';

class RoleGate extends StatefulWidget {
  final User user;
  const RoleGate({super.key, required this.user});

  @override
  State<RoleGate> createState() => _RoleGateState();
}

class _RoleGateState extends State<RoleGate> {
  bool _showRolePicker = true;

  @override
  Widget build(BuildContext context) {
    final db = Db();
    return StreamBuilder<Map<String, dynamic>?>(
      stream: db.watchProfile(widget.user.uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = snap.data;
        if (_showRolePicker || profile == null) {
          return _ChooseRole(
            user: widget.user,
            db: db,
            profile: profile,
            onRoleSelected: () => setState(() => _showRolePicker = false),
          );
        }
        if (profile['role'] == 'shop') {
          return OrderBoardScreen(
            user: widget.user,
            shopId: profile['shopId'] as String,
          );
        }
        return ShopListScreen(user: widget.user);
      },
    );
  }
}

class _ChooseRole extends StatelessWidget {
  final User user;
  final Db db;
  final Map<String, dynamic>? profile;
  final VoidCallback onRoleSelected;
  const _ChooseRole({
    required this.user,
    required this.db,
    required this.profile,
    required this.onRoleSelected,
  });

  Future<void> _pickCustomer() async {
    await db.becomeCustomer(user.uid, user.displayName ?? '');
    onRoleSelected();
  }

  Future<void> _pickShop(BuildContext context) async {
    final existingShopId = profile?['shopId'] as String?;
    if (existingShopId != null && existingShopId.isNotEmpty) {
      await db.switchToShop(user.uid, user.displayName ?? '');
      onRoleSelected();
      return;
    }

    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ตั้งชื่อร้านของคุณ'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'เช่น ครัวคุณยาย',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('สร้างร้าน'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await db.becomeShop(user.uid, user.displayName ?? '', name);
      onRoleSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เลือกบทบาทการใช้งาน')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.waving_hand_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'ยินดีต้อนรับ${user.displayName == null ? '' : ' ${user.displayName}'}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'เลือกวิธีใช้งาน MSU Food',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _RoleCard(
                  icon: Icons.ramen_dining_rounded,
                  title: 'สั่งอาหาร',
                  detail: 'เลือกร้านอาหาร สั่งเมนู และติดตามออร์เดอร์',
                  actionLabel: 'เลือกเป็นลูกค้า',
                  onTap: _pickCustomer,
                ),
                const SizedBox(height: 14),
                _RoleCard(
                  icon: Icons.storefront_rounded,
                  title: 'จัดการร้านค้า',
                  detail: 'รับออร์เดอร์ จัดการเมนู และดูประวัติการขาย',
                  actionLabel: 'เลือกเป็นร้านค้า',
                  onTap: () => _pickShop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final String actionLabel;
  final VoidCallback onTap;
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  icon,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      actionLabel,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
