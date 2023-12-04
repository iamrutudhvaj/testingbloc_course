import 'dart:convert';
import 'dart:developer' as devtools show log;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension Log on Object {
  void log() => devtools.log(toString());
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BlocProvider(
        create: (context) => PersonsBloc(),
        child: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

@immutable
abstract class LoadAction {
  const LoadAction();
}

@immutable
class LoadPersonsAction implements LoadAction {
  final PersonUrl url;
  const LoadPersonsAction({required this.url}) : super();
}

enum PersonUrl {
  persons1,
  persons2,
}

extension UrlString on PersonUrl {
  String get urlString {
    switch (this) {
      case PersonUrl.persons1:
        return "http://192.168.29.119:5500/api/persons1.json";
      case PersonUrl.persons2:
        return "http://192.168.29.119:5500/api/persons2.json";
    }
  }
}

extension Subscript<T> on Iterable<T> {
  T? operator [](int index) => length > index ? elementAt(index) : null;
}

@immutable
class Person {
  final String name;
  final int age;

  const Person({required this.name, required this.age});

  Person.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        age = json['age'] as int;

  @override
  String toString() => 'Person(name: $name, age: $age)';
}

@immutable
class FetchResult {
  final Iterable<Person> persons;
  final bool isRetrievedFromCache;

  const FetchResult(
      {required this.persons, required this.isRetrievedFromCache});

  @override
  String toString() =>
      'FetchResult(persons: $persons, isRetrievedFromCache: $isRetrievedFromCache)';
}

class PersonsBloc extends Bloc<LoadAction, FetchResult?> {
  final Map<PersonUrl, Iterable<Person>> _cache = {};
  PersonsBloc() : super(null) {
    on<LoadPersonsAction>((event, emit) async {
      PersonUrl url = event.url;
      if (_cache.containsKey(url)) {
        final persons = _cache[url]!;
        final result =
            FetchResult(persons: persons, isRetrievedFromCache: true);
        emit(result);
      } else {
        final persons = await getPersons(url.urlString);
        _cache[url] = persons;
        final result =
            FetchResult(persons: persons, isRetrievedFromCache: false);
        emit(result);
      }
    });
  }
}

Future<Iterable<Person>> getPersons(String url) => HttpClient()
    .getUrl(Uri.parse(url))
    .then((req) => req.close())
    .then((res) => res.transform(utf8.decoder).join())
    .then((str) => jsonDecode(str) as List<dynamic>)
    .then((list) => list.map((e) => Person.fromJson(e)));

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                  onPressed: () {
                    context
                        .read<PersonsBloc>()
                        .add(const LoadPersonsAction(url: PersonUrl.persons1));
                  },
                  child: const Text("Load Json #1")),
              TextButton(
                  onPressed: () {
                    context
                        .read<PersonsBloc>()
                        .add(const LoadPersonsAction(url: PersonUrl.persons2));
                  },
                  child: const Text("Load Json #2")),
            ],
          ),
          BlocBuilder<PersonsBloc, FetchResult?>(
            buildWhen: (previous, current) =>
                previous?.persons != current?.persons,
            builder: (context, fetchResults) {
              fetchResults?.log();
              final persons = fetchResults?.persons;
              if (persons == null) {
                return const SizedBox.shrink();
              }
              return Expanded(
                child: ListView.builder(
                  itemCount: persons.length,
                  itemBuilder: (context, index) {
                    final person = persons[index]!;
                    return ListTile(
                      title: Text(person.name),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
