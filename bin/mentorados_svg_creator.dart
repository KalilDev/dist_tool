import 'dart:convert';
import 'dart:io';

import 'package:mentorados_svg_creator/template_model.dart';

import 'package:mentorados_svg_creator/user_model.dart';
import 'package:args/args.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'template',
      abbr: 't',
      defaultsTo: 'assets/template.svg',
    )
    ..addOption(
      'iconsDir',
      defaultsTo: 'assets',
    )
    ..addOption(
      'input',
      abbr: 'i',
    )
    ..addOption(
      'output',
      abbr: 'o',
      defaultsTo: 'output',
    );
  final r = parser.parse(arguments);

  final userStream = File(ArgumentError.checkNotNull(r['input']))
      .openRead()
      .transform(utf8.decoder)
      .transform(LineSplitter())
      .skip(2)
      .map(DemostudoUser.decode);

  final template = await Template.load(File(
    ArgumentError.checkNotNull(r['template']),
  ));
  final icons = await Icons.load(Directory(
    ArgumentError.checkNotNull(r['iconsDir']),
  ));
  final out = Directory(ArgumentError.checkNotNull(r['output']));
  if (out.existsSync()) {
    await out.delete(recursive: true);
  }
  await out.create();

  final resultFiles = await userStream
      .map((user) => UserSvgBuilder.from(template, icons).build(user))
      .mapI((svg, i) => svg.writeTo(out, i))
      .toList()
      .then((files) => Future.wait(files));
  print('Success! The following files have been created.');
  print(resultFiles.join());
}

extension _MapI<T> on Stream<T> {
  Stream<T1> mapI<T1>(T1 Function(T, int) fn) {
    var i = 0;
    return map((e) => fn(e, i++));
  }
}
