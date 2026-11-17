import 'package:flutter_test/flutter_test.dart';

import 'package:demoo/main.dart';

void main() {
  test('vnd định dạng tiền Việt', () {
    expect(vnd(65000), '65.000đ');
    expect(vnd(190000), '190.000đ');
    expect(vnd(0), '0đ');
  });

  testWidgets('thêm món vào giỏ thì hiện số trên giỏ hàng', (tester) async {
    await tester.pumpWidget(const YummyApp());
    expect(find.text('Bếp Nhà Mình'), findsOneWidget);

    await tester.tap(find.text('Phở bò tái'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Thêm vào giỏ'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget); // Badge
  });
}
