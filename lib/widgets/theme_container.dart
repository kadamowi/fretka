import 'package:flutter/material.dart';

class ThemedContainer extends StatelessWidget {
  final Widget? child;

  const ThemedContainer({
    super.key,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      decoration: BoxDecoration(color: Colors.yellow[50], border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }
}
