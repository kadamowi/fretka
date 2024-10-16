import 'package:flutter/material.dart';

class ItemContainer extends StatelessWidget {
  final Widget? child;

  const ItemContainer({
    super.key,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      decoration: BoxDecoration(color: Colors.blue[50], border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }
}
