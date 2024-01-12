import 'dart:convert';

import 'package:growthbook_sdk_flutter/growthbook_sdk_flutter.dart';
import 'package:growthbook_sdk_flutter/src/Network/see_client.dart';
import 'package:growthbook_sdk_flutter/src/Utils/crypto.dart';

class FeatureViewModel {
  const FeatureViewModel({
    required this.delegate,
    required this.source,
    this.encryptionKey,
    this.backgroundSync,
  });
  final FeaturesFlowDelegate delegate;
  final FeatureDataSource source;
  final String? encryptionKey;
  final bool? backgroundSync;

  Future<void> fetchFeature(String? sseURL) async {
    if (sseURL != null) {
      if (backgroundSync ?? false) {
        var streamingUpdate = SSEManager.subscribeToSSE(
          method: SSERequestType.GET,
          url: sseURL,
          header: {"Authorization": "Bearer basic-auth-token"},
        );

        streamingUpdate.listen((sseModel) {
          // Handle SSE data here
          if (sseModel.event == "features") {
            var jsonData = sseModel.data;
            prepareFeaturesData(jsonData);
          }
        });

        // Uncomment the following line if you want to unsubscribe at some point
        // SSEManager.unsubscribeFromSSE();
      } else {
        // Unsubscribe from SSE
        SSEManager.unsubscribeFromSSE();
      }
    } else {
      await source.fetchFeatures(
        (data) => delegate.featuresFetchedSuccessfully(
          data.features,
        ),
        (e, s) => delegate.featuresFetchFailed(
          GBError(
            error: e,
            stackTrace: s.toString(),
          ),
        ),
      );
    }
  }

  void prepareFeaturesData(dynamic data) {
    final Map<String, dynamic>? jsonPetitions = jsonDecode(data);

    if (jsonPetitions != null) {
      if (jsonPetitions.containsKey('features')) {
        final features = jsonPetitions['features'];

        if (features != null && features) {
          delegate.featuresFetchedSuccessfully(features);
        } else {
          final encryptedString = jsonPetitions['encryptedFeatures'];

          if (encryptedString != null &&
              encryptedString &&
              encryptedString.isNotEmpty) {
            if (encryptionKey != null && encryptionKey!.isNotEmpty) {
              final crypto = Crypto();
              final extractedFeatures = crypto.getFeaturesFromEncryptedFeatures(
                encryptedString,
                encryptionKey!,
              );

              if (extractedFeatures != null) {
                delegate.featuresFetchedSuccessfully(extractedFeatures);
              } else {
                delegate.featuresFetchFailed(
                    const GBError(stackTrace: 'failedMissingKey'));
                return;
              }
            } else {
              delegate.featuresFetchFailed(
                  const GBError(stackTrace: 'failedMissingKey'));
              return;
            }
          } else {
            delegate.featuresFetchFailed(
                const GBError(stackTrace: 'failedParsedData'));
            return;
          }
        }
      } else {
        delegate
            .featuresFetchFailed(const GBError(stackTrace: 'failedParsedData'));
        return;
      }
    }
  }
}
