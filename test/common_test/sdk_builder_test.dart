import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growthbook_sdk_flutter/growthbook_sdk_flutter.dart';

import '../mocks/network_mock.dart';

void main() {
  group('Initialization', () {
    const testApiKey = '<API_KEY>';
    const attr = <String, String>{};
    const testHostURL = 'https://example.growthbook.io/';
    const testSseUrl = "https://host.com/sub/4r23r324f23";
    const client = MockNetworkClient();

    test("- default", () async {
      final sdk = await GBSDKBuilderApp(
        apiKey: testApiKey,
        sseUrl: testSseUrl,
        hostURL: testHostURL,
        attributes: attr,
        client: client,
        growthBookTrackingCallBack: (experiment, experimentResult) {},
        backgroundSync: false,
      ).initialize();

      /// Test API key
      expect(sdk.context.apiKey, testApiKey);

      /// Test sse URL
      expect(sdk.context.sseUrl, testSseUrl);

      /// Feature mode
      expect(sdk.context.enabled, true);

      /// Test HostUrl
      expect(sdk.context.hostURL, testHostURL);

      /// Test qaMode
      expect(sdk.context.qaMode, false);

      /// Test passed attr.
      expect(sdk.context.attributes, attr);
    });

    test('- qa mode', () async {
      const variations = <String, int>{};

      final sdk = await GBSDKBuilderApp(
        apiKey: testApiKey,
        sseUrl: testSseUrl,
        qaMode: true,
        client: client,
        forcedVariations: variations,
        hostURL: testHostURL,
        attributes: attr,
        growthBookTrackingCallBack: (exp, result) {},
        backgroundSync: false,
      ).initialize();
      expect(sdk.context.enabled, true);
      expect(sdk.context.qaMode, true);
    });

    test('- with initialization assertion cause of wrong host url', () async {
      expect(
        () => GBSDKBuilderApp(
          apiKey: testApiKey,
          sseUrl: testSseUrl,
          hostURL: "https://example.growthbook.io",
          client: client,
          growthBookTrackingCallBack: (_, __) {},
          backgroundSync: false,
        ),
        throwsAssertionError,
      );
    });

    test('- with network client', () async {
      GrowthBookSDK sdk = await GBSDKBuilderApp(
              apiKey: testApiKey,
              sseUrl: testSseUrl,
              hostURL: testHostURL,
              attributes: attr,
              client: client,
              growthBookTrackingCallBack: (exp, result) {},
              backgroundSync: false,
      )
          .initialize();
      final featureValue = sdk.feature('fwrfewrfe');
      expect(featureValue.source, GBFeatureSource.unknownFeature);
      final result = sdk.run(GBExperiment(key: "fwrfewrfe"));
      expect(result.variationID, 0);
    });

    test(
      '- with failed network client',
      () async {
        GrowthBookSDK sdk = await GBSDKBuilderApp(
          apiKey: testApiKey,
          sseUrl: testSseUrl,
          hostURL: testHostURL,
          attributes: attr,
          client: const MockNetworkClient(error: true),
          growthBookTrackingCallBack: (exp, result) {},
          gbFeatures: {'some-feature': GBFeature(defaultValue: true)},
          backgroundSync: false,
        ).initialize();
        final featureValue = sdk.feature('some-feature');
        expect(featureValue.value, true);

        final result = sdk.run(GBExperiment(key: "some-feature"));
        expect(result.variationID, 0);
      },
    );

    test(
      '- onInitializationFailure callback test',
      () async {
        GBError? error;

        await GBSDKBuilderApp(
          apiKey: testApiKey,
          sseUrl: testSseUrl,
          hostURL: testHostURL,
          attributes: attr,
          client: const MockNetworkClient(error: true),
          growthBookTrackingCallBack: (exp, result) {},
          gbFeatures: {'some-feature': GBFeature(defaultValue: true)},
          onInitializationFailure: (e) => error = e,
          backgroundSync: false,
        ).initialize();

        expect(error != null, true);
        expect(error?.error is DioException, true);
        expect(error?.stackTrace != null, true);
      },
    );
  });
}
