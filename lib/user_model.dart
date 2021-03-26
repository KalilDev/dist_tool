import 'dart:convert';

enum Mentoria {
  atualidades,
  edFinanceira,
  estudarFora,
  extracurriculares,
  politicaECidadania,
  redacao,
  softSkills,
  nenhuma,
}

enum Evolucao {
  semente,
  broto,
  miniMuda,
  regador,
  plantinha,
  peDeFeijao,
}

enum Engajamento {
  flash,
  luzCameraAcao,
  duvida,
}

enum Evento {
  ouro,
  prata,
  bronze,
  mestreKahoot,
}

class DemostudoUser {
  final String name;
  final Set<Mentoria> mentorias;
  final List<Engajamento> engajamentos;
  final List<Evolucao> evolucao;
  final List<Evento> eventos;

  DemostudoUser(
    this.name,
    this.mentorias,
    this.engajamentos,
    this.evolucao,
    this.eventos,
  );
  static final _decoder = DemostudoUserDecoder();
  static DemostudoUser decode(String s) => _decoder.convert(s);
}

Set<T> _setFromFields<T>(Iterable<String> strings, List<T> values) {
  final results = <T>{};
  var i = 0;
  for (final f in strings) {
    if (f.isNotEmpty && f != '0') {
      results.add(values[i]);
    }
    i++;
  }
  return results;
}

List<T> _listFromFields<T>(Iterable<String> strings, List<T> values) {
  final results = <T>[];
  for (final f in strings) {
    final i = int.tryParse(f);
    if (i == null) {
      continue;
    }
    results.add(values[i - 1]);
  }
  return results;
}

class DemostudoUserDecoder extends Converter<String, DemostudoUser> {
  @override
  DemostudoUser convert(String input) {
    final parts = input.split(',');
    final name = parts[0];
    final mentorias = parts.skip(1).take(6);
    final engajamentos = parts.skip(1 + 6).take(6);
    final evolucao = parts.skip(1 + 6 + 6).take(6);
    final eventos = parts.skip(1 + 6 + 6 + 6).take(6);
    return DemostudoUser(
      name,
      _setFromFields(mentorias, Mentoria.values),
      _listFromFields(engajamentos, Engajamento.values),
      _listFromFields(evolucao, Evolucao.values),
      _listFromFields(eventos, Evento.values),
    );
  }
}
