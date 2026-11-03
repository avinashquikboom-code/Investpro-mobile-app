import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';

class InvestorEmailPreferences extends StatefulWidget {
  final ApiService? api;
  const InvestorEmailPreferences({super.key, this.api});
  @override
  State<InvestorEmailPreferences> createState() => _InvestorEmailPreferencesState();
}

class _InvestorEmailPreferencesState extends State<InvestorEmailPreferences> {
  Map<String, bool>? _preferences;
  bool _saving = false;
  String? _error;
  ApiService get _api => widget.api ?? Get.find<ApiService>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await _api.getEmailPreferences();
      if (mounted) setState(() { _preferences = values; _error = null; });
    } catch (_) {
      if (mounted) setState(() => _error = 'Email preferences unavailable.');
    }
  }

  Future<void> _save(String key, bool value) async {
    setState(() { _saving = true; _error = null; });
    try {
      final values = await _api.updateEmailPreference(key, value);
      if (mounted) setState(() => _preferences = values);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save email preferences. Please retry.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (_preferences == null && _error == null)
        const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
      if (_error != null)
        Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          Text(_error!),
          if (_preferences == null) TextButton(onPressed: _load, child: const Text('Retry')),
        ])),
      if (_preferences != null)
        for (final entry in const {
          'serviceEmails': 'Investment and account emails',
          'dailyReports': 'Daily portfolio emails',
          'projectAnnouncements': 'New project announcements',
        }.entries)
          SwitchListTile(
            title: Text(entry.value),
            value: _preferences![entry.key] ?? false,
            onChanged: _saving ? null : (value) => _save(entry.key, value),
          ),
    ]);
  }
}
