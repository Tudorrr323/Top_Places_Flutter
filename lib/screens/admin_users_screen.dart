import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_places/models/profile.dart';
import 'package:top_places/services/account_service.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/view_models/account_view_model.dart';
import 'package:top_places/widgets/dialogs.dart';
import 'package:top_places/widgets/list_search_field.dart';

/// Which accounts the list shows.
enum _Shown { requests, suspended, all }

/// Asks for the details of a change (a confirmation, a reason, a name) and
/// returns it, or null when cancelled.
typedef _Ask = Future<ProfileUpdate?> Function();

/// For admins: every account, with what an admin can do to each. The
/// database allows it to admins only, and never on their own account.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  _Shown _shown = _Shown.requests;
  String _query = '';
  late Future<List<Profile>> _profiles;

  @override
  void initState() {
    super.initState();
    _profiles = _load();
  }

  Future<List<Profile>> _load() =>
      context.read<AccountService?>()?.allProfiles() ?? Future.value(const []);

  void _reload() {
    setState(() {
      _profiles = _load();
    });
  }

  /// Asks for the details of a change with [ask], then saves it.
  Future<void> _change(Profile profile, _Ask ask) async {
    final update = await ask();
    if (update == null || !mounted) return;
    final service = context.read<AccountService?>()!;
    final repository = context.read<PlacesRepository>();
    final account = context.read<AccountViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await service.updateProfile(profile.id, update);
      // A new name of the admin's own shows on the Profil tab too.
      if (profile.id == account.profile?.id) await account.refresh();
      // Suspending an operator hides their places from Explore, and
      // reactivating brings them back.
      await repository.refresh();
      if (mounted) _reload();
    } on AccountException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AccountViewModel>().profile?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Utilizatori')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: ListSearchField(
                  hint: 'Caută după nume sau email',
                  onChanged: (query) => setState(() => _query = query),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (shown, label) in const [
                      (_Shown.requests, 'Cereri de operator'),
                      (_Shown.suspended, 'Suspendați'),
                      (_Shown.all, 'Toți'),
                    ])
                      ChoiceChip(
                        label: Text(label),
                        selected: _shown == shown,
                        onSelected: (_) => setState(() => _shown = shown),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder(
                  future: _profiles,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.error case final error?) {
                      return Center(child: Text(error.toString()));
                    }
                    final profiles = snapshot.data!
                        .where(
                          (profile) => switch (_shown) {
                            _Shown.requests =>
                              profile.operatorRequest ==
                                  OperatorRequest.pending,
                            _Shown.suspended => profile.isSuspended,
                            _Shown.all => true,
                          },
                        )
                        .where(
                          (profile) => matchesSearch(_query, [
                            profile.fullName,
                            profile.email,
                          ]),
                        )
                        .toList();
                    if (profiles.isEmpty) {
                      return const Center(child: Text('Niciun cont aici.'));
                    }
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final profile in profiles)
                          _UserCard(
                            profile: profile,
                            isMe: profile.id == myId,
                            onChange: (ask) => _change(profile, ask),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One account, with only the actions that make sense for it now:
/// a request is answered first, and a suspended account is reactivated
/// before anything else changes on it.
class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.profile,
    required this.isMe,
    required this.onChange,
  });

  final Profile profile;

  /// The admin's own account: no role changes and no suspension.
  final bool isMe;
  final void Function(_Ask ask) onChange;

  String get _name =>
      profile.fullName.isEmpty ? profile.email : profile.fullName;

  @override
  Widget build(BuildContext context) {
    final hasRequest =
        profile.operatorRequest == OperatorRequest.pending && !isMe;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (!profile.isSuspended && !hasRequest) _menu(context),
              ],
            ),
            Text(_details()),
            if (profile.isSuspended || hasRequest)
              Align(
                alignment: Alignment.centerRight,
                child: OverflowBar(
                  spacing: 4,
                  children: profile.isSuspended
                      ? [
                          FilledButton(
                            onPressed: () =>
                                onChange(() => _confirmReactivation(context)),
                            child: const Text('Reactivează'),
                          ),
                        ]
                      : [
                          TextButton(
                            onPressed: () =>
                                onChange(() => _askRejection(context)),
                            child: const Text('Respinge'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                onChange(() => _confirmOperator(context)),
                            child: const Text('Aprobă'),
                          ),
                        ],
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// The ⋮ menu of an active account without a request.
  Widget _menu(BuildContext context) {
    final items = <(String, _Ask)>[
      ('Schimbă numele', () => _askName(context)),
      if (!isMe) ...[
        for (final role in Role.values)
          if (role != profile.role)
            (
              switch (role) {
                Role.user => 'Fă-l utilizator',
                Role.operator => 'Fă-l operator',
                Role.admin => 'Fă-l administrator',
              },
              () async => ProfileUpdate.role(role),
            ),
        ('Suspendă contul', () => _askSuspension(context)),
      ],
    ];
    return PopupMenuButton<_Ask>(
      tooltip: 'Acțiuni pentru $_name',
      onSelected: onChange,
      itemBuilder: (context) => [
        for (final (label, ask) in items)
          PopupMenuItem(value: ask, child: Text(label)),
      ],
    );
  }

  String _details() {
    final role = switch (profile.role) {
      Role.user => 'Utilizator',
      Role.operator => 'Operator de localuri',
      Role.admin => 'Administrator',
    };
    final state = profile.isSuspended
        ? 'Suspendat: ${profile.suspendedReason}'
        : switch (profile.operatorRequest) {
            OperatorRequest.pending => 'Vrea să devină operator',
            OperatorRequest.rejected =>
              'Cerere respinsă: ${profile.operatorRequestReason}',
            null => 'Activ',
          };
    return '${profile.email}\n$role · $state';
  }

  Future<ProfileUpdate?> _confirmOperator(BuildContext context) async {
    final confirmed = await askConfirmation(
      context,
      title: 'Îl faci pe $_name operator?',
      message: 'Va putea adăuga localuri, care apar după ce le aprobi.',
      action: 'Aprobă',
    );
    return confirmed ? ProfileUpdate.role(Role.operator) : null;
  }

  Future<ProfileUpdate?> _askRejection(BuildContext context) async {
    final reason = await askReason(
      context,
      title: 'Respingi cererea lui $_name?',
      action: 'Respinge',
    );
    return reason == null ? null : ProfileUpdate.rejectOperatorRequest(reason);
  }

  Future<ProfileUpdate?> _confirmReactivation(BuildContext context) async {
    final confirmed = await askConfirmation(
      context,
      title: 'Reactivezi contul lui $_name?',
      message:
          'Va putea folosi din nou contul, iar localurile lui reapar în '
          'Explorează.',
      action: 'Reactivează',
    );
    return confirmed ? ProfileUpdate.reactivate() : null;
  }

  Future<ProfileUpdate?> _askName(BuildContext context) async {
    final names = await askName(
      context,
      firstName: profile.firstName,
      lastName: profile.lastName,
    );
    return names == null ? null : ProfileUpdate.name(names.$1, names.$2);
  }

  Future<ProfileUpdate?> _askSuspension(BuildContext context) async {
    final reason = await askReason(
      context,
      title: 'Suspenzi contul lui $_name?',
      action: 'Suspendă',
    );
    return reason == null ? null : ProfileUpdate.suspend(reason);
  }
}
