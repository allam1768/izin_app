import 'package:flutter/material.dart';

/// Modal aktivasi lisensi (selalu sukses di aplikasi standalone)
class ActivationModal extends StatelessWidget {
  const ActivationModal({super.key});

  static Future<bool?> show(BuildContext context) async {
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
