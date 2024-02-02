import 'package:qioqioqr/src/Utils/converter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:tuple/tuple.dart';

@Tuple2Converter()
@JsonSerializable()
class Tuple2Wrapper {
  Tuple2<double, double> tuple;

  Tuple2Wrapper(this.tuple);
}
