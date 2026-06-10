import 'package:flutter_test/flutter_test.dart';
import 'package:eco_bitacora/main.dart';
import 'package:eco_bitacora/screens/home_screen.dart'; // Importante para encontrar el tipo SplashScreen

void main() {
  testWidgets('Prueba de humo: carga inicial', (WidgetTester tester) async {
    // 1. Iniciamos la app con el Splash
    await tester.pumpWidget(const MyApp(showHome: false));

    // 2. Verificamos que cargó el Splash correctamente
    expect(find.byType(SplashScreen), findsOneWidget);

    // 3. Esperamos a que pasen los 3 segundos del Timer y las animaciones
    // pumpAndSettle avanza el reloj hasta que no haya nada pendiente
    await tester.pumpAndSettle();

    // 4. Ahora verificamos que el Splash ya no esté (porque ya navegó)
    expect(find.byType(SplashScreen), findsNothing);
  });
}
