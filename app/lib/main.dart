import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app/main.dart';
import 'package:app/user_widgets.dart';
import 'package:flutter/material.dart';
import 'package:mentorados_svg_creator/user_model.dart';
import 'package:path/path.dart' as p;
import 'package:mentorados_svg_creator/user_model.dart' as um;
import 'package:mentorados_svg_creator/template_model.dart' as tm;
import 'package:flutter_svg/flutter_svg.dart' as fsvg;
import 'package:url_launcher/url_launcher.dart' as url;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        cardTheme: CardTheme(
          margin: EdgeInsets.all(16.0),
        ),
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Directory output;
  tm.Icons icons;
  tm.Template template;
  File templateFile;
  File csv;
  List<DemostudoUser> users;
  String loadError;
  final subs = <StreamSubscription>[];
  void initState() {
    super.initState();
    init();
  }

  void onTemplateUpdate() async {
    template = await tm.Template.load(templateFile);
  }

  void onCsvUpdate() async {
    print('onUpdate');
    if (await csv.exists()) {
      setState(() {
        loadError = null;
        users = null;
      });

      try {
        final newUsers = await csv
            .openRead()
            .transform(utf8.decoder)
            .transform(LineSplitter())
            .skip(2)
            .map(um.DemostudoUser.decode)
            .toList();

        setState(() => users = newUsers);
      } catch (e) {
        setState(() => loadError = 'Houve erro: $e');
      }
    } else {
      setState(() => loadError =
          'O arquivo ${csv.absolute.path}, que deve conter a tabela, não existe.');
    }
  }

  void init() async {
    final hadTemplate = templateFile != null;
    final hadCsv = csv != null;

    final assetRoot = Directory('assets');
    output = Directory('output');
    icons = await tm.Icons.load(assetRoot);
    templateFile = File('template.svg');
    csv = File('mentorados.csv');

    const events = FileSystemEvent.all;
    /*FileSystemEvent.modify |
        FileSystemEvent.delete |
        FileSystemEvent.create;*/

    if (!hadTemplate)
      subs.add(templateFile
          .watch(events: events) //
          .listen((_) => onTemplateUpdate()));
    if (!hadCsv)
      subs.add(csv
          .watch(events: events) //
          .listen((_) => onCsvUpdate()));

    await onTemplateUpdate();
    await onCsvUpdate();
  }

  Widget _body(BuildContext context) {
    if (loadError != null) {
      return Center(child: Text(loadError));
    }
    if (users == null) {
      return Center(child: CircularProgressIndicator());
    }
    return Scrollbar(
      child: ListView.builder(
        itemBuilder: (c, i) => DemostudoUserCard(
          user: users[i],
          icons: icons,
        ),
        itemCount: users.length,
      ),
    );
  }

  VoidCallback _save(BuildContext context) => () {
        if (template == null) {
          showDialog(
            context: context,
            builder: (c) => AlertDialog(
              title: Text('Erro'),
              content: Text(
                  'O template, que deveria estar em ${templateFile.absolute.path} não foi encontrada.'),
            ),
          );
          return;
        }
        showDialog(
            context: context,
            builder: (c) => SaveDialog(
                  template: template,
                  output: output,
                  users: users,
                  icons: icons,
                ));
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bem vindo Lucas!'),
      ),
      body: _body(context),
      floatingActionButton: FloatingActionButton(
        onPressed: _save(context),
        tooltip: 'Salvar',
        child: Icon(Icons.save),
      ),
    );
  }
}

class SaveDialog extends StatefulWidget {
  final Directory output;
  final tm.Icons icons;
  final tm.Template template;
  final List<DemostudoUser> users;

  const SaveDialog({
    Key key,
    this.output,
    this.icons,
    this.template,
    this.users,
  }) : super(key: key);
  @override
  _SaveDialogState createState() => _SaveDialogState();
}

class _SaveDialogState extends State<SaveDialog> {
  List<File> files;
  void initState() {
    super.initState();
    save();
  }

  void save() async {
    final r = await Future.wait(
      widget.users
          .map((u) => tm.UserSvgBuilder //
                  .from(widget.template, widget.icons)
              .build(u))
          .mapI((svg, i) => svg //
              .writeTo(widget.output, i)),
    );
    setState(() => files = r);
  }

  @override
  Widget build(BuildContext context) {
    if (files == null) {
      return AlertDialog(
        title: Text('Salvando'),
        content: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return AlertDialog(
        title: Text('Salvo!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final file in files)
              ListTile(
                title: Text(p.absolute(file.path)),
                onTap: () => url.launch(file.uri.toString()),
              )
          ],
        ));
  }
}

extension _MapI<T> on Iterable<T> {
  Iterable<T1> mapI<T1>(T1 Function(T, int) fn) {
    var i = 0;
    return map((e) => fn(e, i++));
  }
}
