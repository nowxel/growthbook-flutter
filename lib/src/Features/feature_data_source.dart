import 'package:qioqioqr/qioqioqr.dart';
import 'package:qioqioqr/src/Utils/feature_url_builder.dart';

typedef FeatureFetchSuccessCallBack = void Function(
  FeaturedDataModel featuredDataModel,
);

abstract class FeaturesFlowDelegate {
  void featuresFetchedSuccessfully(GBFeatures gbFeatures);
  void featuresFetchFailed(GBError? error);
}

class FeatureDataSource {
  FeatureDataSource({
    required this.context,
    required this.client,
  });
  final GBContext context;
  final BaseClient client;

  Future<void> fetchFeatures(
      FeatureFetchSuccessCallBack onSuccess, OnError onError) async {
    final api = FeatureURLBuilder.buildUrl(context.hostURL!, context.apiKey!);
    await client.consumeGetRequest(
      api,
      (response) => onSuccess(
        FeaturedDataModel.fromJson(response),
      ),
      onError,
    );
  }
}
