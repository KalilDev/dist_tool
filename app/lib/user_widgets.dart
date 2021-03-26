import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mentorados_svg_creator/user_model.dart';
import 'package:mentorados_svg_creator/template_model.dart' as t;

class _CardSection extends StatelessWidget {
  final String name;
  final t.Icons icons;
  final List<Object> items;

  const _CardSection({
    Key key,
    this.name,
    this.icons,
    this.items,
  }) : super(key: key);

  Widget _body(BuildContext context) {
    if (items.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text('Não há'),
      );
    }
    return ListView.separated(
      itemBuilder: (c, i) => IconWidget(icon: icons.iconFor(items[i])),
      itemCount: items.length,
      scrollDirection: Axis.horizontal,
      separatorBuilder: (_, __) => SizedBox(
        width: 4.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 8),
        Text(name, style: textTheme.subtitle1.copyWith(letterSpacing: 1.25)),
        SizedBox(height: 4),
        SizedBox(height: 48, child: _body(context))
      ],
    );
  }
}

class DemostudoUserCard extends StatelessWidget {
  final DemostudoUser user;
  final t.Icons icons;

  const DemostudoUserCard({
    Key key,
    this.user,
    this.icons,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(user.name, style: textTheme.headline5),
            SizedBox(height: 4),
            _CardSection(
              icons: icons,
              name: 'Mentorias',
              items: user.mentorias.toList(),
            ),
            _CardSection(
              icons: icons,
              name: 'Evolução',
              items: user.evolucao,
            ),
            _CardSection(
              icons: icons,
              name: 'Engajamentos',
              items: user.engajamentos,
            ),
            _CardSection(
              icons: icons,
              name: 'Eventos',
              items: user.eventos,
            ),
          ],
        ),
      ),
    );
  }
}

class IconWidget extends StatelessWidget {
  final t.Icon icon;

  const IconWidget({Key key, this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.file(icon.file);
  }
}
