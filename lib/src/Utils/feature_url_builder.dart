class FeatureURLBuilder {
  static const String featurePath = "api/features";
  static const String eventsPath = "sub/";

  static String buildUrl(
      String baseUrl,
      String apiKey, {
        FeatureRefreshStrategy featureRefreshStrategy = FeatureRefreshStrategy.STALE_WHILE_REVALIDATE,
      }) {
    String endpointPath =
    featureRefreshStrategy == FeatureRefreshStrategy.SERVER_SENT_EVENTS
        ? eventsPath
        : featurePath;

    String baseUrlWithFeaturePath =
    baseUrl.endsWith('/') ? '$baseUrl$endpointPath' : '$baseUrl/$endpointPath';

    return '$baseUrlWithFeaturePath/$apiKey';
  }
}

enum FeatureRefreshStrategy {
  STALE_WHILE_REVALIDATE,
  SERVER_SENT_EVENTS,
}
