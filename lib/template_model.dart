import 'dart:io';

import 'package:mentorados_svg_creator/user_model.dart';
import 'package:xml/xml.dart';
import 'package:tuple/tuple.dart';
import 'package:path/path.dart' as p;

class Icon {
  final XmlDocument document;

  Icon._(this.document);
  static Future<Icon> read(File f) async {
    final contents = await f.readAsString();
    return Icon._(XmlDocument.parse(contents));
  }

  XmlElement get svg => document.rootElement;

  List<XmlNode> _iconDefs;
  Iterable<XmlNode> get iconDefs =>
      (_iconDefs ??= svg.getElement('defs').children.toList())
          .map((el) => el.copy());

  XmlElement _icon;
  XmlElement get icon => (_icon ??= svg.getElement('g')).copy();

  void writeToDoc(XmlDocument doc, String locationId) {
    doc.rootElement.getElement('defs').children.insertAll(0, iconDefs);
    final location = _findOnSvg(doc, locationId);
    location.children.retainWhere((node) => false);
    location.children.insert(0, icon);
  }
}

class Icons {
  final Map<Engajamento, Icon> engajamentos;
  final Map<Evolucao, Icon> evolucoes;
  final Map<Evento, Icon> eventos;
  final Map<Mentoria, Icon> mentorias;

  Icons._(
    this.engajamentos,
    this.evolucoes,
    this.eventos,
    this.mentorias,
  );

  static Future<Map<T, Icon>> _loadIcons<T>(
    List<String> filenames,
    Directory parent,
    String folderName,
    List<T> values,
  ) =>
      Future.wait(
        filenames
            .map((e) => p.join(parent.path, folderName, e))
            .map((p) => File(p))
            .mapI((f, i) => Icon.read(f).then(
                  (icon) => MapEntry(values[i], icon),
                )),
      ).then((es) => Map.fromEntries(es));

  static Future<Icons> load(Directory dir) async {
    final engajamentos = _loadIcons(
      _engajamentos,
      dir,
      'catalogo-0',
      Engajamento.values,
    );
    final evolucoes = _loadIcons(
      _evolucoes,
      dir,
      'catalogo-1',
      Evolucao.values,
    );
    final eventos = _loadIcons(
      _eventos,
      dir,
      'catalogo-2',
      Evento.values,
    );
    final mentorias = _loadIcons(
      _mentorias,
      dir,
      'catalogo-3',
      Mentoria.values,
    );

    return Icons._(
      await engajamentos,
      await evolucoes,
      await eventos,
      await mentorias,
    );
  }

  static const _engajamentos = [
    '0flash.svg',
    '1camera.svg',
    '2duvida.svg',
  ];
  static const _evolucoes = [
    '0semente.svg',
    '1broto.svg',
    '2miniMuda.svg',
    '3regador.svg',
    '4plantinha.svg',
    '5peDoJoao.svg',
  ];
  static const _eventos = [
    '0ouro.svg',
    '1prata.svg',
    '2bronze.svg',
  ];
  static const _mentorias = [
    '0atualidades.svg',
    '1edFinanceira.svg',
    '2estudarFora.svg',
    '3extraCurriculares.svg',
    '4politica.svg',
    '5redacao.svg',
    '6softSkills.svg',
  ];
}

class Template {
  final XmlDocument document;

  Template._(this.document);

  final String slotNome = 'tspan3463';
  final Set<String> slotMentorias = {
    'g2293',
    'g2311',
    'g2329',
    'g2347',
    'g2597',
    'g2775',
  };
  final Set<String> slotEngajamento = {
    'g3113',
    'g3131',
    'g3149',
    'g3167',
    'g3185',
    'g3203',
  };
  final Set<String> slotEvolucao = {
    'g3005',
    'g3023',
    'g3041',
    'g3059',
    'g3077',
    'g3095',
  };
  final Set<String> slotEventos = {
    'g3221',
    'g3239',
    'g3257',
    'g3275',
    'g3293',
    'g3311',
  };
  static Future<Template> load(File f) => f
      .readAsString() //
      .then((s) => Template._(XmlDocument.parse(s)));
}

class ResultingSvg {
  final Template _template;
  final XmlDocument _document;
  ResultingSvg._(this._template, this._document);
  bool populated = false;

  factory ResultingSvg.from(Template t) {
    final doc = t.document.copy();
    return ResultingSvg._(t, doc);
  }

  void _write(Tuple2<String, Icon> kv) =>
      kv.item2.writeToDoc(_document, kv.item1);

  void fillWith(Icons icons, DemostudoUser user) {
    final engIcns = user.engajamentos.map((e) => icons.engajamentos[e]);
    final eveIcns = user.eventos.map((e) => icons.eventos[e]);
    final menIcns = user.mentorias.map((e) => icons.mentorias[e]);
    final evoIcns = user.evolucao.map((e) => icons.evolucoes[e]);

    iterBoth(_template.slotEngajamento, engIcns).forEach(_write);
    iterBoth(_template.slotEventos, eveIcns).forEach(_write);
    iterBoth(_template.slotMentorias, menIcns).forEach(_write);
    iterBoth(_template.slotEvolucao, evoIcns).forEach(_write);
    final name = _findOnSvg(_document, _template.slotNome);
    name.innerText = user.name;
    populated = true;
  }

  Future<File> writeTo(File file) async {
    if (!populated) {
      throw StateError('not populated');
    }
    return file.writeAsString(_document.toXmlString());
  }
}

Iterable<Tuple2<A, B>> iterBoth<A, B>(Iterable<A> a, Iterable<B> b) sync* {
  final aIter = a.iterator;
  final bIter = b.iterator;
  while (aIter.moveNext() && bIter.moveNext()) {
    yield Tuple2(aIter.current, bIter.current);
  }
}

extension _IndexedIter<T> on Iterable<T> {
  Iterable<T1> mapI<T1>(T1 Function(T, int) fn) sync* {
    var i = 0;
    final it = iterator;

    while (it.moveNext()) {
      yield fn(it.current, i);
      i++;
    }
  }

  void forEachI(void Function(T, int) fn) {
    var i = 0;
    final it = iterator;
    while (it.moveNext()) {
      fn(it.current, i);
      i++;
    }
  }
}

extension _MonadicIterable<T> on Iterable<T> {
  Iterable<T1> bind<T1>(Iterable<T1> Function(T) fn) sync* {
    for (final t in this) {
      yield* fn(t);
    }
  }
}

XmlElement _findOnSvg(XmlDocument doc, String id) => doc.rootElement.children
    .whereType<XmlElement>()
    .where((element) => element.name.local != 'defs')
    .bind((el) => el.descendants)
    .firstWhere((el) => el.getAttribute('id') == id);
