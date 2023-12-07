import 'package:flutter/foundation.dart' show immutable;
import 'package:testingbloc_course/bloc/persons.dart';

const persons1Url = 'http://192.168.29.119:5500/api/persons1.json';
const persons2Url = 'http://192.168.29.119:5500/api/persons2.json';

typedef PersonsLoader = Future<Iterable<Person>> Function(String url);

@immutable
abstract class LoadAction {
  const LoadAction();
}

@immutable
class LoadPersonsAction implements LoadAction {
  final String url;
  final PersonsLoader loader;
  const LoadPersonsAction({
    required this.url,
    required this.loader,
  }) : super();
}
