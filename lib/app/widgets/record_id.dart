import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full backend identifiers for administrative detail and support workflows.
class RecordId extends StatelessWidget {
  final String label;
  final String? value;
  const RecordId({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final id = value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: SelectableText('$label: ${id == null || id.isEmpty ? 'N/A' : id}', style: Theme.of(context).textTheme.bodySmall)),
        if (id != null && id.isNotEmpty)
          IconButton(tooltip: 'Copy $label', visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: id));
              if (context.mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text('$label copied')));
            }),
      ]),
    );
  }
}

class RecordIds extends StatelessWidget {
  final Map<String, String> values;
  const RecordIds({super.key, required this.values});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: values.entries.map((entry) => RecordId(
      label: entry.key == 'id' ? 'Record ID' : entry.key.replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m[0]}').replaceAll(' Id', ' ID'),
      value: entry.value,
    )).toList(),
  );
}
