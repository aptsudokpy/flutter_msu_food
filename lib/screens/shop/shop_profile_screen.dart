import 'package:flutter/material.dart';
import '../../models/shop.dart';
import '../../services/db.dart';

class ShopProfileScreen extends StatelessWidget {
  final String shopId;

  const ShopProfileScreen({super.key, required this.shopId});

  static const _members = [
    ('66010914061', 'สุชาวดี สุระสิงห์'),
    ('66010914068', 'ณหทัย โกสิลา'),
    ('66010914090', 'จักริน อินทราราม'),
    ('66010914154', 'รัชชานนท์ พรดีมา'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์ร้านค้า')),
      body: StreamBuilder<Shop>(
        stream: Db().watchShop(shopId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('ผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final shop = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.storefront_rounded,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: shop.isOpen
                                    ? const Color(0xFFE7F6EF)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                shop.isOpen ? 'เปิดรับออร์เดอร์' : 'ปิดร้าน',
                                style: TextStyle(
                                  color: shop.isOpen
                                      ? const Color(0xFF168354)
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'ทีมงานร้าน',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < _members.length; i++) ...[
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person_outline_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          _members[i].$2,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('รหัสประจำตัว ${_members[i].$1}'),
                      ),
                      if (i != _members.length - 1)
                        const Divider(height: 1, indent: 72),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}