// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ever_animes/app/app.dart';
import 'package:ever_animes/core/data/dtos/anime_item_dto.dart';
import 'package:ever_animes/core/data/dtos/paginated_anime_response_dto.dart';
import 'package:ever_animes/features/home/presentation/home_providers.dart';
import 'package:ever_animes/features/meta/presentation/meta_providers.dart';

/// Overrides para isolar a Home de chamadas HTTP reais.
final _testOverrides = [
      seasonNowProvider.overrideWith(
        (ref) async => PaginatedAnimeResponseDto(
          items: [
            AnimeItemDto(
              source: 'anilist',
              id: 1,
              externalId: '100',
              title: 'Test Anime',
              year: 2025,
              score: 85,
              coverUrl: null,
            ),
          ],
          nextCursor: null,
        ),
      ),
      genresProvider.overrideWith(
        (ref) async => ['Action', 'Comedy', 'Drama'],
      ),
    ];

void main() {
  // Garante SharedPreferences vazio para testes (sem sessão restaurada).
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Home shows banner and login icon when unauthenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _testOverrides,
        child: const EverAnimesApp(),
      ),
    );

    // Primeiro pump: deixa o restoreSession (async) completar.
    await tester.pump();
    // Segundo pump: deixa o rebuild do widget tree completar.
    await tester.pumpAndSettle();

    // AppBar title
    expect(find.text('EverAnimes'), findsOneWidget);

    // Banner
    expect(find.text('Bem-vindo ao EverAnimes'), findsOneWidget);
    expect(
      find.text('Descubra os animes da temporada atual'),
      findsOneWidget,
    );

    // Login icon (not authenticated) – no profile icon
    expect(find.byIcon(Icons.login), findsOneWidget);
    expect(find.byIcon(Icons.account_circle), findsNothing);

    // Section title
    expect(find.text('Temporada Atual'), findsOneWidget);

    // Test anime from override
    expect(find.text('Test Anime'), findsOneWidget);

    // Genre chips
    expect(find.text('Action'), findsOneWidget);
    expect(find.text('Comedy'), findsOneWidget);
  });

  testWidgets('Theme toggle icon is visible', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _testOverrides,
        child: const EverAnimesApp(),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Dark mode padrão → ícone de light_mode para mudar
    expect(find.byIcon(Icons.light_mode), findsOneWidget);
  });
}
