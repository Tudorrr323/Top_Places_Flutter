import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_places/models/profile.dart';
import 'package:top_places/screens/admin_places_screen.dart';
import 'package:top_places/screens/admin_users_screen.dart';
import 'package:top_places/view_models/account_view_model.dart';
import 'package:top_places/widgets/dialogs.dart';
import 'package:top_places/widgets/my_places.dart';

/// The Profil tab: sign in or create an account; once signed in, the
/// account, the request to become an operator and signing out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountViewModel>();
    final profile = account.profile;

    return Scaffold(
      // No refresh button: opening the tab loads the account again (see
      // HomeShell).
      appBar: AppBar(title: const Text('Profil')),
      body: Center(
        // On wide windows the forms stay readable instead of stretching.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!account.isAvailable)
                const Text(
                  'Conturile nu sunt disponibile în această versiune a '
                  'aplicației: lipsește configurarea Supabase.',
                )
              else if (profile == null)
                const _SignInForm()
              else
                _AccountDetails(profile: profile),
              if (account.error case final error?) ...[
                const SizedBox(height: 16),
                // Read out by screen readers as soon as it appears.
                Semantics(
                  liveRegion: true,
                  child: Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Sign in, or create an account with the same form and a few more fields.
class _SignInForm extends StatefulWidget {
  const _SignInForm();

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  bool _newAccount = false;

  /// Shows the password as text, for checking what was typed.
  bool _showPassword = false;

  /// Set after a sign-up: the address the confirmation email went to.
  String? _confirmationSentTo;

  @override
  void dispose() {
    for (final controller in [_email, _password, _firstName, _lastName]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final account = context.read<AccountViewModel>();
    if (!_newAccount) {
      await account.signIn(_email.text, _password.text);
      return;
    }
    final created = await account.signUp(
      email: _email.text,
      password: _password.text,
      firstName: _firstName.text,
      lastName: _lastName.text,
    );
    if (created && mounted) {
      setState(() {
        _confirmationSentTo = _email.text.trim();
        _newAccount = false;
        _password.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AccountViewModel>().isBusy;
    final sentTo = _confirmationSentTo;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Intră în cont')),
              ButtonSegment(value: true, label: Text('Cont nou')),
            ],
            selected: {_newAccount},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                setState(() => _newAccount = selection.single),
          ),
          const SizedBox(height: 16),
          if (sentTo != null && !_newAccount)
            Card.filled(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Ți-am trimis un email la $sentTo. Deschide linkul din el, '
                  'apoi intră în cont aici. Dacă nu îl vezi, caută și în '
                  'Spam.',
                ),
              ),
            ),
          if (_newAccount) ...[
            TextFormField(
              controller: _firstName,
              decoration: const InputDecoration(labelText: 'Prenume'),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.givenName],
              validator: _required,
            ),
            TextFormField(
              controller: _lastName,
              decoration: const InputDecoration(labelText: 'Nume'),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.familyName],
              validator: _required,
            ),
          ],
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: (value) =>
                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())
                ? null
                : 'Scrie o adresă de email validă.',
          ),
          TextFormField(
            controller: _password,
            decoration: InputDecoration(
              labelText: 'Parolă',
              suffixIcon: _showPasswordButton(),
            ),
            obscureText: !_showPassword,
            textInputAction: TextInputAction.done,
            autofillHints: [
              _newAccount ? AutofillHints.newPassword : AutofillHints.password,
            ],
            onFieldSubmitted: (_) => _submit(),
            validator: (value) => _newAccount && value!.length < 8
                ? 'Parola trebuie să aibă cel puțin 8 caractere.'
                : _required(value),
          ),
          if (_newAccount)
            TextFormField(
              decoration: const InputDecoration(labelText: 'Repetă parola'),
              // The same button shows both passwords, to compare them.
              obscureText: !_showPassword,
              validator: (value) =>
                  value == _password.text ? null : 'Parolele nu sunt la fel.',
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : _submit,
            child: Text(_newAccount ? 'Creează contul' : 'Intră în cont'),
          ),
        ],
      ),
    );
  }

  Widget _showPasswordButton() {
    return IconButton(
      // The tooltip is also what screen readers say.
      tooltip: _showPassword ? 'Ascunde parola' : 'Arată parola',
      icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
      onPressed: () => setState(() => _showPassword = !_showPassword),
    );
  }

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Câmp obligatoriu.' : null;
}

/// The signed-in account: suspension, name, role and what comes with it.
class _AccountDetails extends StatelessWidget {
  const _AccountDetails({required this.profile});

  final Profile profile;

  Future<void> _editName(BuildContext context) async {
    final account = context.read<AccountViewModel>();
    final names = await askName(
      context,
      firstName: profile.firstName,
      lastName: profile.lastName,
    );
    if (names != null) {
      await account.updateName(names.$1, names.$2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final account = context.watch<AccountViewModel>();
    final busy = account.isBusy;
    final suspended = profile.isSuspended;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (suspended)
          Card(
            color: theme.colorScheme.errorContainer,
            child: ListTile(
              leading: Icon(
                Icons.block,
                color: theme.colorScheme.onErrorContainer,
              ),
              title: Text(
                'Contul tău e suspendat',
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
              subtitle: Text(
                'Motiv: ${profile.suspendedReason}\nPoți vedea localurile, '
                'dar nu poți face modificări.',
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ),
        Card(
          child: ListTile(
            title: Semantics(
              header: true,
              child: Text(
                profile.fullName.isEmpty ? 'Fără nume' : profile.fullName,
                style: theme.textTheme.titleLarge,
              ),
            ),
            subtitle: Text('${profile.email}\n${_roleLabel(profile.role)}'),
            isThreeLine: true,
            trailing: IconButton(
              tooltip: 'Schimbă numele',
              onPressed: busy || suspended ? null : () => _editName(context),
              icon: const Icon(Icons.edit),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ..._roleSection(context, account),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: busy ? null : account.signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Ieși din cont'),
        ),
      ],
    );
  }

  /// What the role adds: an operator's places, or the request to become an
  /// operator.
  List<Widget> _roleSection(BuildContext context, AccountViewModel account) {
    if (profile.role == Role.admin) {
      // A suspended admin keeps the role but loses the tools, in the
      // database as well.
      if (profile.isSuspended) return const [];
      void open(Widget screen) =>
          Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (context) => screen));
      return [
        Semantics(
          header: true,
          child: Text(
            'Administrare',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: () => open(const AdminPlacesScreen()),
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Localuri: aprobări și suspendări'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: () => open(const AdminUsersScreen()),
          icon: const Icon(Icons.manage_accounts_outlined),
          label: const Text('Utilizatori și operatori'),
        ),
      ];
    }
    if (profile.role == Role.operator) {
      // A new key for every loaded profile: the list loads again with it.
      return [MyPlaces(key: ObjectKey(profile), canEdit: !profile.isSuspended)];
    }
    if (profile.isSuspended) return const [];
    return switch (profile.operatorRequest) {
      OperatorRequest.pending => const [
        Text('Ai cerut să devii operator. Un administrator îți va răspunde.'),
      ],
      final request => [
        if (request == OperatorRequest.rejected)
          Text(
            'Cererea ta de a deveni operator a fost respinsă. Motiv: '
            '${profile.operatorRequestReason}',
          ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: account.isBusy ? null : account.requestOperatorRole,
          icon: const Icon(Icons.storefront),
          label: Text(
            request == OperatorRequest.rejected
                ? 'Trimite din nou cererea'
                : 'Vreau să adaug localuri',
          ),
        ),
      ],
    };
  }

  static String _roleLabel(Role role) => switch (role) {
    Role.user => 'Utilizator',
    Role.operator => 'Operator de localuri',
    Role.admin => 'Administrator',
  };
}
