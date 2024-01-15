import 'dart:convert';

import 'package:dio/dio.dart';
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
        ((e, s) {
          delegate.featuresFetchFailed(
            GBError(
              error: DioException(
                type: DioExceptionType.unknown,
                requestOptions: RequestOptions(path: '', baseUrl: ''),
                response: null,
                error:
                'SocketException: Failed host lookup: \'cdn.growthbook.io\' (OS Error: nodename nor servname provided, or not known, errno = 8)',
              ),
              stackTrace: s.toString(),
            ),
          );
        })(null, null); // Call the anonymous function with appropriate parameters
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
    try {
      final Map<String, dynamic>? jsonPetitions = jsonDecode(data);

      if (jsonPetitions != null) {
        if (jsonPetitions.containsKey('features')) {
          final features = jsonPetitions['features'];

          if (features != null && features) {
            delegate.featuresFetchedSuccessfully(features);
          } else {
            final encryptedString = jsonPetitions['encryptedFeatures'];

            if (encryptedString != null &&
                encryptedString is String &&
                encryptedString.isNotEmpty) {
              if (encryptionKey != null && encryptionKey!.isNotEmpty) {
                try {
                  final crypto = Crypto();
                  final extractedFeatures = crypto.getFeaturesFromEncryptedFeatures(
                    encryptedString,
                    encryptionKey!,
                  );

                  if (extractedFeatures != null) {
                    delegate.featuresFetchedSuccessfully(extractedFeatures);
                  } else {
                     print('Failed to extract features from encrypted string.');
                  }
                } catch (e, s) {
                  delegate.featuresFetchFailed(GBError(error: e, stackTrace: s.toString()));
                  return;
                }
              } else {
                 print('Encryption key is missing.');
              }
            } else {
               print('Failed to parse encrypted data.');
            }
          }
        } else {
           print('Failed to parse data. Missing "features" key.');
        }
      }
    } catch (e, s) {
      delegate.featuresFetchFailed(GBError(error: e, stackTrace: s.toString()));
    }
  }
}
