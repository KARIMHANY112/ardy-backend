import 'package:ardy/l10n/generated/app_localizations.dart';
import 'package:ardy/models/listing.dart';
import 'package:ardy/screens/listings/home_feed_screen.dart';
import 'package:ardy/services/api_client.dart';
import 'package:ardy/services/listings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _StubListingsRepository extends ListingsRepository {
  _StubListingsRepository(this.listings) : super(ApiClient());

  final List<Listing> listings;

  @override
  Future<List<Listing>> browse() async => listings;
}

Listing _listing({required String id, required String title, required OfferType offerType}) => Listing(
      id: id,
      refCode: 'REF-$id',
      title: title,
      category: ListingCategory.shop,
      offerType: offerType,
      price: 1000,
      sizeSqm: 100,
      location: 'Tanta',
      description: '',
      license: LicenseStatus.licensed,
    );

Widget _harness(List<Listing> listings) => Provider<ListingsRepository>(
      create: (_) => _StubListingsRepository(listings),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeFeedScreen(),
      ),
    );

void main() {
  final saleListing = _listing(id: '1', title: 'Shop for sale', offerType: OfferType.sale);
  final rentListing = _listing(id: '2', title: 'Shop to let', offerType: OfferType.rent);

  testWidgets('filter button opens the sheet once listings have loaded', (tester) async {
    // Regression: the button was gated on state written inside the FutureBuilder's
    // builder, which runs after the header is built — so it never re-enabled and
    // tapping it did nothing.
    await tester.pumpWidget(_harness([saleListing, rentListing]));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    expect(find.text('Filters'), findsOneWidget);
  });

  testWidgets('applying an offer-type filter narrows the feed', (tester) async {
    await tester.pumpWidget(_harness([saleListing, rentListing]));
    await tester.pumpAndSettle();
    expect(find.text('2 listings'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.text('For Rent'));
    await tester.pumpAndSettle();

    // The sheet counts against the listings that would actually show.
    expect(find.text('Show 1 result'), findsOneWidget);

    await tester.tap(find.text('Show 1 result'));
    await tester.pumpAndSettle();

    expect(find.text('Shop to let'), findsOneWidget);
    expect(find.text('Shop for sale'), findsNothing);
    expect(find.text('1 listing'), findsOneWidget);
  });

  testWidgets('clearing filters restores the full feed', (tester) async {
    await tester.pumpWidget(_harness([saleListing, rentListing]));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.text('For Rent'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show 1 result'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('2 listings'), findsOneWidget);
    expect(find.text('Shop for sale'), findsOneWidget);
  });
}
