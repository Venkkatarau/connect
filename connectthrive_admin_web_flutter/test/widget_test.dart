import 'package:flutter_test/flutter_test.dart';

import 'package:connectthrive_admin_web_flutter/main.dart';

void main() {
  testWidgets('ConnectThrive Admin login screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ConnectThriveAdminWeb());

    // Verify that the login text or button is present
    expect(find.textContaining('Login'), findsWidgets);
  });
}
