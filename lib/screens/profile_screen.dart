import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_places/l10n/l10n.dart';
import 'package:top_places/models/profile.dart';
import 'package:top_places/screens/admin_places_screen.dart';
import 'package:top_places/screens/admin_users_screen.dart';
import 'package:top_places/screens/ratings_moderation_screen.dart';
import 'package:top_places/view_models/account_view_model.dart';
import 'package:top_places/view_models/language_settings.dart';
import 'package:top_places/view_models/theme_settings.dart';
import 'package:top_places/widgets/dialogs.dart';
import 'package:top_places/widgets/language_flag.dart';
import 'package:top_places/widgets/my_places.dart';

/// The Profil tab: sign in or create an account; once signed in, the
/// account, the request to become an operator and signing out. The settings
/// (the language) are there too, with or without an account.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountViewModel>();
    final profile = account.profile;
    final l10n = context.l10n;

    return Scaffold(
      // No refresh button: opening the tab loads the account again (see
      // HomeShell).
      appBar: AppBar(title: Text(l10n.tabProfile)),
      body: Center(
        // On wide windows the forms stay readable instead of stretching.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!account.isAvailable)
                Text(l10n.accountsUnavailable)
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
                    l10n.accountError(error),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              const _Settings(),
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
    final l10n = context.l10n;
    String? required(String? value) =>
        value == null || value.trim().isEmpty ? l10n.requiredField : null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(l10n.signIn)),
              ButtonSegment(value: true, label: Text(l10n.newAccount)),
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
                child: Text(l10n.confirmationSent(sentTo)),
              ),
            ),
          if (_newAccount) ...[
            TextFormField(
              controller: _firstName,
              decoration: InputDecoration(labelText: l10n.firstName),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.givenName],
              validator: required,
            ),
            TextFormField(
              controller: _lastName,
              decoration: InputDecoration(labelText: l10n.lastName),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.familyName],
              validator: required,
            ),
          ],
          TextFormField(
            controller: _email,
            decoration: InputDecoration(labelText: l10n.email),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: (value) =>
                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())
                ? null
                : l10n.invalidEmail,
          ),
          TextFormField(
            controller: _password,
            decoration: InputDecoration(
              labelText: l10n.password,
              suffixIcon: _showPasswordButton(),
            ),
            obscureText: !_showPassword,
            textInputAction: TextInputAction.done,
            autofillHints: [
              _newAccount ? AutofillHints.newPassword : AutofillHints.password,
            ],
            onFieldSubmitted: (_) => _submit(),
            validator: (value) => _newAccount && value!.length < 8
                ? l10n.passwordTooShort
                : required(value),
          ),
          if (_newAccount)
            TextFormField(
              decoration: InputDecoration(labelText: l10n.repeatPassword),
              // The same button shows both passwords, to compare them.
              obscureText: !_showPassword,
              validator: (value) =>
                  value == _password.text ? null : l10n.passwordsDiffer,
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : _submit,
            child: Text(_newAccount ? l10n.createAccount : l10n.signIn),
          ),
        ],
      ),
    );
  }

  Widget _showPasswordButton() {
    return IconButton(
      // The tooltip is also what screen readers say.
      tooltip: _showPassword
          ? context.l10n.hidePassword
          : context.l10n.showPassword,
      icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
      onPressed: () => setState(() => _showPassword = !_showPassword),
    );
  }
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
    final l10n = context.l10n;
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
                l10n.accountSuspended,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
              subtitle: Text(
                l10n.accountSuspendedDetails(profile.suspendedReason ?? ''),
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ),
        Card(
          child: ListTile(
            title: Semantics(
              header: true,
              child: Text(
                profile.fullName.isEmpty ? l10n.noName : profile.fullName,
                style: theme.textTheme.titleLarge,
              ),
            ),
            subtitle: Text(
              '${profile.email}\n${_roleLabel(l10n, profile.role)}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              tooltip: l10n.changeName,
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
          label: Text(l10n.signOut),
        ),
      ],
    );
  }

  /// What the role adds: an operator's places and their reviews, the
  /// admin's tools, or the request to become an operator.
  List<Widget> _roleSection(BuildContext context, AccountViewModel account) {
    final l10n = context.l10n;
    void open(Widget screen) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (context) => screen));
    final reviews = FilledButton.tonalIcon(
      onPressed: () => open(const RatingsModerationScreen()),
      icon: const Icon(Icons.reviews_outlined),
      label: Text(
        profile.role == Role.admin ? l10n.reviewsAdmin : l10n.reviewsOperator,
      ),
    );

    if (profile.role == Role.admin) {
      // A suspended admin keeps the role but loses the tools, in the
      // database as well.
      if (profile.isSuspended) return const [];
      return [
        Semantics(
          header: true,
          child: Text(
            l10n.administration,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: () => open(const AdminPlacesScreen()),
          icon: const Icon(Icons.fact_check_outlined),
          label: Text(l10n.adminPlaces),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: () => open(const AdminUsersScreen()),
          icon: const Icon(Icons.manage_accounts_outlined),
          label: Text(l10n.adminUsers),
        ),
        const SizedBox(height: 8),
        reviews,
      ];
    }
    if (profile.role == Role.operator) {
      return [
        // A new key for every loaded profile: the list loads again with it.
        MyPlaces(key: ObjectKey(profile), canEdit: !profile.isSuspended),
        // Suspended, the operator no longer decides about reviews.
        if (!profile.isSuspended) ...[const SizedBox(height: 16), reviews],
      ];
    }
    if (profile.isSuspended) return const [];
    return switch (profile.operatorRequest) {
      OperatorRequest.pending => [Text(l10n.operatorRequestPending)],
      final request => [
        if (request == OperatorRequest.rejected)
          Text(
            l10n.operatorRequestRejected(profile.operatorRequestReason ?? ''),
          ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: account.isBusy ? null : account.requestOperatorRole,
          icon: const Icon(Icons.storefront),
          label: Text(
            request == OperatorRequest.rejected
                ? l10n.sendRequestAgain
                : l10n.wantToAddPlaces,
          ),
        ),
      ],
    };
  }

  static String _roleLabel(AppLocalizations l10n, Role role) => switch (role) {
    Role.user => l10n.roleUser,
    Role.operator => l10n.roleOperator,
    Role.admin => l10n.roleAdmin,
  };
}

/// The settings of the app, with or without an account: the language and
/// the theme.
class _Settings extends StatelessWidget {
  const _Settings();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = context.watch<LanguageSettings>();
    final theme = context.watch<ThemeSettings>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.settings,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        // Icons, each with its name as a tooltip, which screen readers say.
        _SettingRow(
          label: l10n.language,
          choice: SegmentedButton<Locale>(
            segments: [
              // Each language named in itself, so it can be found from the
              // other one.
              for (final (locale, name) in const [
                (LanguageSettings.romanian, 'Română'),
                (LanguageSettings.english, 'English'),
              ])
                ButtonSegment(
                  value: locale,
                  icon: LanguageFlag(locale),
                  tooltip: name,
                ),
            ],
            selected: {language.locale},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                language.choose(selection.single),
          ),
        ),
        const SizedBox(height: 8),
        _SettingRow(
          label: l10n.theme,
          choice: SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                icon: const Icon(Icons.brightness_auto),
                tooltip: l10n.themeSystem,
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode),
                tooltip: l10n.themeLight,
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode),
                tooltip: l10n.themeDark,
              ),
            ],
            selected: {theme.mode},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => theme.choose(selection.single),
          ),
        ),
      ],
    );
  }
}

/// A setting on one line: its name, and the choice next to it.
class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.choice});

  final String label;
  final Widget choice;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 16),
        choice,
      ],
    );
  }
}
