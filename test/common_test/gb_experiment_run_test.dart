import 'package:flutter_test/flutter_test.dart';
import 'package:qioqioqr/qioqioqr.dart';

import '../Helper/gb_test_helper.dart';

void main() {
  group('GBExperimentRun Test', () {
    late final List evaluateCondition;
    setUpAll(() {
      evaluateCondition = GBTestHelper.getRunExperimentData();
    });

    test('Evaluate Feature', () {
      final failedScenarios = <String>[];
      final passedScenarios = <String>[];
      int failingIndex = 0;
      final listOfFailingIndex = <int>[];

      for (var item in evaluateCondition) {
        if (item is List) {
          final testContext = GBContextTest.fromMap(item[1]);
          final experiment = GBExperiment.fromJson(item[2]);

          final attr = testContext.attributes;

          final gbContext = GBContext(
              apiKey: '',
              hostURL: '',
              sseUrl: null,
              enabled: testContext.enabled,
              attributes: attr,
              forcedVariation: testContext.forcedVariations,
              qaMode: testContext.qaMode,
              trackingCallBack: (_, __) {},
              backgroundSync: false,
          );

          final result = GBExperimentEvaluator.evaluateExperiment(
              context: gbContext, experiment: experiment);
          final status = item[0].toString() +
              "\nExpected Result - " +
              item[3].toString() +
              " & " +
              item[4].toString() +
              "\nActual result - " +
              result.value.toString() +
              " & " +
              "${result.inExperiment}" +
              "\n\n";
          if (item[3].toString() == result.value.toString() &&
              item[4].toString() == result.inExperiment.toString()) {
            passedScenarios.add(status);
          } else {
            failedScenarios.add(status);
            listOfFailingIndex.add(failingIndex);
          }
          failingIndex++;
        }
      }
      customLogger(
          'Passed Test ${passedScenarios.length} out of ${evaluateCondition.length}');
      expect(failedScenarios.length, 0);
    });
  });
}
