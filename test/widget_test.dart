import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_msu_food/models/food_order.dart';

void main() {
  test('order status advances through the expected flow', () {
    expect(OrderStatus.next(OrderStatus.pending), OrderStatus.accepted);
    expect(OrderStatus.next(OrderStatus.accepted), OrderStatus.cooking);
    expect(OrderStatus.next(OrderStatus.cooking), OrderStatus.ready);
    expect(OrderStatus.next(OrderStatus.ready), OrderStatus.completed);
    expect(OrderStatus.next(OrderStatus.completed), isNull);
    expect(OrderStatus.next(OrderStatus.cancelled), isNull);
  });

  test('order item subtotal uses its quantity', () {
    final item = OrderItem(name: 'ข้าวผัด', price: 45, qty: 2);

    expect(item.subtotal, 90);
  });
}
