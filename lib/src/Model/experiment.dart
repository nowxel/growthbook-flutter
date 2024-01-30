import 'package:growthbook_sdk_flutter/growthbook_sdk_flutter.dart';
import 'package:growthbook_sdk_flutter/src/Utils/converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'experiment.g.dart';

/// Defines a single experiment
@JsonSerializable(createToJson: false)
class GBExperiment {
  GBExperiment({
    this.key,
    this.variations = const [],
    this.namespace,
    this.condition,
    this.hashAttribute,
    this.weights,
    this.active = true,
    this.coverage,
    this.force,
    this.hashVersion,
    this.ranges,
    this.meta,
    this.filters,
    this.seed,
    this.name,
    this.phase,
  });

  /// The globally unique tracking key for the experiment
  String? key;

  /// The different variations to choose between
  List variations = [];

  /// A tuple that contains the namespace identifier, plus a range of coverage for the experiment
  List? namespace;

  /// All users included in the experiment will be forced into the specific variation index
  String? hashAttribute;

  /// How to weight traffic between variations. Must add to 1.
  List? weights;

  /// If set to false, always return the control (first variation)
  bool active;

  /// What percent of users should be included in the experiment (between 0 and 1, inclusive)
  double? coverage;

  /// Optional targeting condition
  GBCondition? condition;

  /// All users included in the experiment will be forced into the specific variation index
  int? force;

  ///Check if experiment is not active.
  bool get deactivated => !active;

  //new properties v0.4.0
  /// The hash version to use (default to 1)
  int? hashVersion;

  /// Array of ranges, one per variation
  @Tuple2Converter()
  List<GBBucketRange>? ranges;

  /// Meta info about the variations
  List<GBVariationMeta>? meta;

  /// Array of filters to apply
  List<GBFilter>? filters;

  /// The hash seed to use
  String? seed;

  /// Human-readable name for the experiment
  String? name;

  /// Id of the current experiment phase
  String? phase;

  factory GBExperiment.fromJson(Map<String, dynamic> value) =>
      _$GBExperimentFromJson(value);
}

/// The result of running an Experiment given a specific Context
@JsonSerializable(createToJson: false)
class GBExperimentResult {
  GBExperimentResult({
    this.inExperiment,
    this.variationID,
    this.value,
    this.hasAttributes,
    this.hashValue,
    this.featureId,
    this.key,
    this.name,
    this.bucket,
    this.passthrough,
  });

  /// Whether or not the user is part of the experiment
  bool? inExperiment;

  /// The array index of the assigned variation
  int? variationID;

  /// The array value of the assigned variation
  dynamic value;

  /// The user attribute used to assign a variation
  String? hasAttributes;

  /// The value of that attribute
  String? hashValue;

  String? featureId;

  //new properties v0.4.0
  /// The unique key for the assigned variation
  String? key;

  /// The human-readable name of the assigned variation
  String? name;

  /// The hash value used to assign a variation (double from 0 to 1)
  double? bucket;

  /// Used for holdout groups
  bool? passthrough;

  factory GBExperimentResult.fromJson(Map<String, dynamic> value) =>
      _$GBExperimentResultFromJson(value);
}
