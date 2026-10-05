import 'package:flutter/material.dart';

/// Asks for a first and a last name, starting from the current ones.
/// Returns them, or null when cancelled.
Future<(String, String)?> askName(
  BuildContext context, {
  required String firstName,
  required String lastName,
}) {
  return showDialog<(String, String)>(
    context: context,
    builder: (context) => _NameDialog(firstName: firstName, lastName: lastName),
  );
}

/// Asks why a place or an account is rejected or suspended. [action] is the
/// button that confirms, e.g. "Suspendă". Returns the reason, or null.
Future<String?> askReason(
  BuildContext context, {
  required String title,
  required String action,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _ReasonDialog(title: title, action: action),
  );
}

/// Asks whether to go ahead with [action], explained by [message]. True
/// only when confirmed.
Future<bool> askConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Renunță'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Câmp obligatoriu.' : null;

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.firstName, required this.lastName});

  final String firstName;
  final String lastName;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _firstName = TextEditingController(text: widget.firstName);
  late final _lastName = TextEditingController(text: widget.lastName);

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, (_firstName.text, _lastName.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schimbă numele'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _firstName,
              decoration: const InputDecoration(labelText: 'Prenume'),
              validator: _required,
            ),
            TextFormField(
              controller: _lastName,
              decoration: const InputDecoration(labelText: 'Nume'),
              validator: _required,
              onFieldSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Renunță'),
        ),
        FilledButton(onPressed: _save, child: const Text('Salvează')),
      ],
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title, required this.action});

  final String title;
  final String action;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _reason.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _reason,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Motivul',
            helperText: 'Îl vede și persoana în cauză.',
          ),
          maxLength: 300,
          maxLines: 3,
          minLines: 1,
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Scrie motivul.' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Renunță'),
        ),
        FilledButton(onPressed: _confirm, child: Text(widget.action)),
      ],
    );
  }
}
