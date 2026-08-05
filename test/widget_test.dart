import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:business_home/app/app.dart';
import 'package:business_home/core/services/auth_service.dart';
import 'package:business_home/core/services/theme_controller.dart';
import 'package:business_home/shared/widgets/site_header.dart';

void main() {
  setUp(() {
    // No platform channels in a widget test — give the theme controller and the API client's
    // token store an in-memory backing instead.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Ilova ishga tushadi va sayt header\'i ko\'rinadi', (WidgetTester tester) async {
    await tester
        .pumpWidget(BusinessHomeApp(themeController: ThemeController(), authService: AuthService()));
    await tester.pump();

    // The site's header — logo wordmark, the hamburger, and the hero's sector tiles under it.
    expect(find.byType(SiteHeader), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.text('Novostroykalar'), findsOneWidget);

    // The home screen fires its section requests on init. There is no network here, so drain the
    // Dio timeout timers before the test ends — otherwise the framework fails on pending timers.
    await tester.pump(const Duration(seconds: 31));
  });
}
