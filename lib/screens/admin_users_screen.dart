import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_places/models/profile.dart';
import 'package:top_places/services/account_service.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/view_models/account_view_model.dart';
import 'package:top_places/widgets/dialogs.dart';

/// Which accounts the list shows.
enum _Shown { requests, suspended, all }

/// For admins: every account, with what an admin can do to each. The
/// database allows it to admins only, and never on their own account.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  _Shown _shown = _Shown.requests;
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
  Future<void> _change(
    Profile profile,
    Future<ProfileUpdate?> Function() ask,
  ) async {
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
                        .toList();
                    if (profiles.isEmpty) {
                      return const Center(child: Text('Niciun cont aici.'));
                    }
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final profile in profiles)
                          Card(
                            child: ListTile(
                              title: Text(
                                profile.fullName.isEmpty
                                    ? profile.email
                                    : profile.fullName,
                              ),
                              subtitle: Text(_details(profile)),
                              isThreeLine: true,
                              trailing: _ActionsMenu(
                                profile: profile,
                                // An admin cannot change their own role or
                                // suspend themselves; the database agrees.
                                isMe: profile.id == myId,
                                onChange: (ask) => _change(profile, ask),
                              ),
                            ),
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

  static String _details(Profile profile) {
    final role = switch (profile.role) {
      Role.user => 'Utilizator',
      Role.operator => 'Operator de localuri',
      Role.admin => 'Administrator',
    };
    final state = profile.isSuspended
        ? 'Suspendat: ${profile.suspendedReason}'
        : switch (profile.operatorRequest) {
            OperatorRequest.pending => 'Vrea să devină operator',
            OperatorRequest.rejected => 'Cerere de operator respinsă',
            null => 'Activ',
          };
    return '${profile.email}\n$role · $state';
  }
}

/// The ⋮ menu of an account, with the changes that make sense for it.
class _ActionsMenu extends StatelessWidget {
  const _ActionsMenu({
    required this.profile,
    required this.isMe,
    required this.onChange,
  });

  final Profile profile;
  final bool isMe;
  final void Function(Future<ProfileUpdate?> Function() ask) onChange;

  @override
  Widget build(BuildContext context) {
    final name = profile.fullName.isEmpty ? profile.email : profile.fullName;

    Future<ProfileUpdate?> rename() async {
      final names = await askName(
        context,
        firstName: profile.firstName,
        lastName: profile.lastName,
      );
      return names == null ? null : ProfileUpdate.name(names.$1, names.$2);
    }

    Future<ProfileUpdate?> suspend() async {
      final reason = await askReason(
        context,
        title: 'Suspenzi contul lui $name?',
        action: 'Suspendă',
      );
      return reason == null ? null : ProfileUpdate.suspend(reason);
    }

    final items = <(String, Future<ProfileUpdate?> Function())>[
      if (profile.operatorRequest == OperatorRequest.pending && !isMe) ...[
        ('Aprobă ca operator', () async => ProfileUpdate.role(Role.operator)),
        ('Respinge cererea', () async => ProfileUpdate.rejectOperatorRequest()),
      ],
      ('Schimbă numele', rename),
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
        if (profile.isSuspended)
          ('Reactivează contul', () async => ProfileUpdate.reactivate())
        else
          ('Suspendă contul', suspend),
      ],
    ];

    return PopupMenuButton<Future<ProfileUpdate?> Function()>(
      tooltip: 'Acțiuni pentru $name',
      onSelected: onChange,
      itemBuilder: (context) => [
        for (final (label, ask) in items)
          PopupMenuItem(value: ask, child: Text(label)),
      ],
    );
  }
}
