import 'dart:io';

import 'package:mentorados_svg_creator/user_model.dart';
import 'package:xml/xml.dart';
import 'package:tuple/tuple.dart';
import 'package:path/path.dart' as p;

class Icon {
  final XmlDocument document;
  final File file;

  Icon._(this.document, this.file);
  static Future<Icon> read(File f) async {
    final contents = await f.readAsString();
    return Icon._(XmlDocument.parse(contents), f);
  }

  XmlElement get svg => document.rootElement;

  List<XmlNode> _iconDefs;
  Iterable<XmlNode> get iconDefs =>
      (_iconDefs ??= svg.getElement('defs').children.toList())
          .map((el) => el.copy());

  XmlElement _icon;
  XmlElement get icon => (_icon ??= svg.getElement('g')).copy();

  XmlElement write(XmlElement location) {
    location.children.retainWhere((node) => false);
    final el = icon;
    location.children.insert(0, el);
    return el;
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

  Icon iconFor(Object e) {
    if (e is Engajamento) {
      return engajamentos[e];
    }
    if (e is Evolucao) {
      return evolucoes[e];
    }
    if (e is Evento) {
      return eventos[e];
    }
    if (e is Mentoria) {
      return mentorias[e];
    }
  }

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
    '7nenhuma.svg',
  ];
}

class Slots {
  final Set<String> slots;
  final String transform;
  final void Function(XmlElement) onCreate;

  Slots(this.slots, {this.transform, this.onCreate});

  void fillWith(
    Iterable<Icon> icons,
    XmlElement Function(Icon, String) write,
  ) {
    iterBoth(slots, icons).forEach((kv) {
      final ie = write(kv.item2, kv.item1);
      if (transform != null && transform.isNotEmpty) {
        ie.setAttribute('transform', transform);
      }
      if (onCreate != null) {
        onCreate(ie);
      }
    });
  }
}

class Template {
  final XmlDocument document;

  Template._(this.document);

  final String slotNome = 'tspan3463';
  final mentorias = Slots({
    'g2293',
    'g2311',
    'g2329',
    'g2347',
    'g2579',
    'g2383',
  }, transform: 'scale(1.3238414)');
  final engajamento = Slots({
    'g3113',
    'g3131',
    'g3149',
    'g3167',
    'g3185',
    'g3203',
  }, transform: 'scale(1.3721091)');
  final evolucao = Slots({
    'g3005',
    'g3023',
    'g3041',
    'g3059',
    'g3077',
    'g3095',
  }, transform: 'matrix(1.3719816,0,0,1.3719816,-9.6687341,-9.5208581)');
  final eventos = Slots(
    {
      'g3221',
      'g3239',
      'g3257',
      'g3275',
      'g3293',
      'g3311',
    },
    transform: 'matrix(1.3796216,0,0,1.3796216,2.2051241,-1.9617009e-6)',
    onCreate: (e) {
      final offender = e.parentElement.parentElement;
      offender.removeAttribute('clip-path');
    },
  );
  static Future<Template> load(File f) => f
      .readAsString() //
      .then((s) => Template._(XmlDocument.parse(s)));
}

class UserSvgBuilder {
  final Template _template;
  final XmlDocument _document;
  final Icons _icons;
  UserSvgBuilder._(this._template, this._document, this._icons);

  factory UserSvgBuilder.from(Template t, Icons i) {
    final doc = t.document.copy();
    return UserSvgBuilder._(t, doc, i);
  }

  final _writtenIconDefs = <Icon>{};

  XmlElement _writeIcon(
    Icon icon,
    String id,
  ) {
    if (!_writtenIconDefs.contains(icon)) {
      _document.rootElement
          .getElement('defs')
          .children
          .insertAll(0, icon.iconDefs);
      _writtenIconDefs.add(icon);
    }
    final element = _findOnSvg(_document, id);
    return icon.write(element);
  }

  void _build(DemostudoUser user) {
    final engIcns = user.engajamentos.map(_icons.iconFor);
    final eveIcns = user.eventos.map(_icons.iconFor);
    final menIcns = user.mentorias.map(_icons.iconFor).followedBy(
          Iterable.generate(6, (_) => _icons.mentorias[Mentoria.nenhuma]),
        );
    final evoIcns = user.evolucao.map(_icons.iconFor);

    _template
      ..engajamento.fillWith(engIcns, _writeIcon)
      ..eventos.fillWith(eveIcns, _writeIcon)
      ..mentorias.fillWith(menIcns, _writeIcon)
      ..evolucao.fillWith(evoIcns, _writeIcon);

    final name = _findOnSvg(_document, _template.slotNome);
    name.innerText = user.name;
  }

  UserSvg build(DemostudoUser user) {
    _build(user);
    return UserSvg._(_document, user);
  }
}

class UserSvg {
  final XmlDocument _document;
  final DemostudoUser user;

  UserSvg._(this._document, this.user);
  Future<File> writeTo(Directory dir, int i) async {
    final f = File(p.join(dir.path, '$i-${user.name}.svg'));
    return f.writeAsString(_document.toXmlString());
  }

  String toXmlString() => _document.toXmlString();
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
