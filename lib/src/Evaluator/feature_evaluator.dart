import 'dart:developer';

import 'package:growthbook_sdk_flutter/growthbook_sdk_flutter.dart';
import 'package:tuple/tuple.dart';

/// Feature Evaluator Class
/// Takes Context and Feature Key
/// Returns Calculated Feature Result against that key

class GBFeatureEvaluator {
  static GBFeatureResult evaluateFeature(GBContext context, String featureKey, dynamic attributeOverrides) {
    /// If we are not able to find feature on the basis of the passed featureKey
    /// then we are going to return unKnownFeature.
    final targetFeature = context.features[featureKey];
    if (targetFeature == null) {
      return _prepareResult(
        value: null,
        source: GBFeatureSource.unknownFeature,
      );
    }

    // Loop through the feature rules (if any)
    final rules = targetFeature.rules;

    // Return if rules is not provided.
    if (rules != null && rules.isNotEmpty) {
      for (var rule in rules) {
        /// If the rule has a condition and it evaluates to false,
        /// skip this rule and continue to the next one.

        if (rule.condition != null) {
          final attr = context.attributes ?? {};
          if (!GBConditionEvaluator()
              .evaluateCondition(attr, rule.condition!)) {
            continue;
          }
        }

        // If there are filters for who is included
        if (rule.filters != null) {
          if (GBUtils.isFilteredOut(rule.filters!, context.attributes)) {
            log("Skip rule because of filters");
            continue;
          }
        }

        if (GBUtils.isFilteredOut(rule.filters, context.attributes)) {
          continue;
        }

        /// If rule.force is set
        if (rule.force != null) {

          if (!GBUtils.isIncludedInRollout(
            context.attributes,
            rule.seed,
            rule.hashAttribute,
            rule.range,
            rule.coverage,
            rule.hashVersion,
          )) {
            log("Skip rule because user not included in rollout");
          }

          /// If rule.coverage is set
          if (rule.coverage != null) {
            final key = rule.hashAttribute ?? Constant.idAttribute;
            final attributeValue = context.attributes?[key].toString() ?? '';

            if (attributeValue.isEmpty) {
              continue;
            } else {
              if (!GBUtils.isIncludedInRollout(
                context.attributes,
                rule.seed,
                rule.hashAttribute,
                rule.range,
                rule.coverage,
                rule.hashVersion,
              )) {
                continue;
              }
              // Compute a hash using the Fowler–Noll–Vo algorithm (specifically fnv32-1a)
              final hashFNV = GBUtils.hash(
                      value: attributeValue, seed: featureKey, version: 1.0) ??
                  0.0;
              // If the hash is greater than rule.coverage, skip the rule

              if (hashFNV > rule.coverage!) {
                continue;
              }
            }
          }
          return _prepareResult(
            value: rule.force,
            source: GBFeatureSource.force,
          );
        } else {
          final exp = GBExperiment(
            key: rule.key ?? featureKey,
            variations: rule.variations ?? [],
            coverage: rule.coverage,
            weights: rule.weights,
            hashAttribute: rule.hashAttribute,
            namespace: rule.namespace,
            force: rule.force,
          );

          final result = GBExperimentEvaluator.evaluateExperiment(
            context: context,
            experiment: exp,
          );

          if (result.inExperiment ?? false) {
            return _prepareResult(
              value: result.value,
              source: GBFeatureSource.experiment,
              experiment: exp,
              experimentResult: result,
            );
          } else {
            // If result.inExperiment is false, skip this rule and continue to the next one.
            continue;
          }
        }
      }
    }
    // Return (value = defaultValue or null, source = defaultValue)
    return _prepareResult(
      value: targetFeature.defaultValue,
      source: GBFeatureSource.defaultValue,
    );
  }

  /// This is a helper method to create a FeatureResult object.
  /// Besides the passed-in arguments, there are two derived values - on and off, which are just the value cast to booleans.
  static GBFeatureResult _prepareResult(
      {required dynamic value,
      required GBFeatureSource source,
      GBExperiment? experiment,
      GBExperimentResult? experimentResult}) {
    final isFalsy = value == null ||
        value.toString() == "false" ||
        value.toString() == '' ||
        value.toString() == "0";

    return GBFeatureResult(
        value: value,
        on: !isFalsy,
        off: isFalsy,
        source: source,
        experiment: experiment,
        experimentResult: experimentResult);
  }
  
  ///This is a helper method to evaluate `filters` for both feature flags and experiments.
  // static bool isFilteredOut({required List<GBFilter> filters, required attributeOverrides, required GBContext context}) {
  //   return filters.any((filter) {
  //     final hashAttribute = getHashAttribute(
  //         attr: filter.attribute,
  //         attributeOverrides: attributeOverrides,
  //         context: context);
  //     final hashValue = hashAttribute.hashCode;

  //     final hash = GBUtils.hash(
  //         seed: filter.seed, value: hashValue.toString(), version: filter.hashVersion!.toDouble());
  //     if (hash == null) {
  //       return true;
  //     }

  //     return !filter.ranges.any((r) => GBUtils.inRange(hash, r));
  //   });
  // }

  // ///Returns tuple out of 2 elements: the attribute itself an its hash value
  // static Tuple2<String, String> getHashAttribute(
  //     {String? attr, required attributeOverrides, required GBContext context}) {
  //   final hashAttr = attr ?? "0";
  //   final hashAttribute = int.parse(hashAttr);
  //   var hashValue = "";

  //   if (attributeOverrides[hashAttribute] != null) {
  //     hashValue = attributeOverrides[hashAttribute].toString();
  //   } else if (context.attributes![hashAttribute] != null) {
  //     hashValue = context.attributes![hashAttribute].toString();
  //   }

  //   return Tuple2(hashAttribute.toString(), hashValue);
  // }
  
  // ///Determines if the user is part of a gradual feature rollout.
  // static bool isIncludedInRollout({
  //   required String seed,
  //   String? hashAttribute,
  //   GBBucketRange? range,
  //   double? coverage,
  //   int? hashVersion,
  //   required attributeOverrides,
  //   required GBContext context,
  // }) {
  //   if (range == null && coverage == null) {
  //     return true;
  //   }

  //   final hashValue = getHashAttribute(
  //           attr: hashAttribute,
  //           attributeOverrides: attributeOverrides,
  //           context: context)
  //       .item2;

  //   final hash = GBUtils.hash(
  //       seed: seed,
  //       value: hashValue,
  //       version: hashVersion != null ? hashVersion.toDouble() : 1.0);

  //   if (hash == null) {
  //     return false;
  //   }

  //   if (range != null) {
  //     return GBUtils.inRange(hash, range);
  //   } else if (coverage != null) {
  //     return hash <= coverage;
  //   } else {
  //     return true;
  //   }
  // }

}
