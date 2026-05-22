import 'package:flutter/material.dart';

import 'package:app_flutter/pages/development/dev003/dev003_search_map_view.dart';

class SalesAreaSearchView extends StatelessWidget {
  const SalesAreaSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 24,
        compact ? 12 : 20,
        compact ? 12 : 24,
        compact ? 12 : 24,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD9DEE7)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const SalesAreaSearchMapFrame(),
        ),
      ),
    );
  }
}
