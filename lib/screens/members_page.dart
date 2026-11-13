import 'package:material_ui/material_ui.dart';

import '../domain/fund_permissions.dart';
import '../models/invite.dart';
import '../models/member_role.dart';
import '../models/membership.dart';
import '../repositories/invite_repository.dart';
import '../repositories/membership_repository.dart';
import 'invite_created_dialog.dart';
import 'invite_member_dialog.dart';

enum _MemberAction { makeOrganizer, makeMember, makeObserver, remove }

/// Lists a fund's members and lets organizers manage them.
class MembersPage extends StatefulWidget {
  const MembersPage({
    super.key,
    required this.fundId,
    required this.fundName,
    required this.currentUserId,
    required this.permissions,
    required this.membershipRepository,
    required this.inviteRepository,
  });

  final String fundId;
  final String fundName;
  final String? currentUserId;
  final FundPermissions permissions;
  final MembershipRepository membershipRepository;
  final InviteRepository inviteRepository;

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  List<Membership> _members = const <Membership>[];
  List<Invite> _invites = const <Invite>[];
  bool _isLoading = true;
  bool _isWorking = false;
  String? _error;

  bool get _canManage => widget.permissions.canManageMembers;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final members = await widget.membershipRepository.getMemberships(
        fundId: widget.fundId,
      );
      final invites = _canManage
          ? await widget.inviteRepository.getPendingInvites(
              fundId: widget.fundId,
            )
          : const <Invite>[];
      if (!mounted) {
        return;
      }
      setState(() {
        _members = members;
        _invites = invites;
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _inviteMember() async {
    final draft = await showDialog<InviteDraft>(
      context: context,
      builder: (_) => const InviteMemberDialog(),
    );
    if (draft == null || !mounted) {
      return;
    }

    await _run(() async {
      final invite = await widget.inviteRepository.createInvite(
        fundId: widget.fundId,
        email: draft.email,
        role: draft.role,
      );
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (_) => InviteCreatedDialog(invite: invite),
      );
      await _load();
    });
  }

  Future<void> _changeRole(Membership member, MemberRole role) async {
    if (member.role == role) {
      return;
    }

    await _run(() async {
      await widget.membershipRepository.setRole(
        fundId: widget.fundId,
        userId: member.userId,
        role: role,
      );
      await _load();
    });
  }

  Future<void> _removeMember(Membership member) async {
    final confirmed = await _confirm(
      title: 'Remove member?',
      message:
          '${member.displayName} will lose access to this fund. '
          'Their entries stay on the ledger.',
      action: 'Remove',
    );
    if (!confirmed || !mounted) {
      return;
    }

    await _run(() async {
      await widget.membershipRepository.removeMember(
        fundId: widget.fundId,
        userId: member.userId,
      );
      await _load();
    });
  }

  Future<void> _cancelInvite(Invite invite) async {
    final confirmed = await _confirm(
      title: 'Cancel invite?',
      message: '${invite.email} will no longer be able to use this code.',
      action: 'Cancel invite',
    );
    if (!confirmed || !mounted) {
      return;
    }

    await _run(() async {
      await widget.inviteRepository.cancelInvite(
        fundId: widget.fundId,
        inviteId: invite.id,
      );
      await _load();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _isWorking = true);
    try {
      await action();
    } on Object catch (error) {
      if (mounted) {
        _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.toString())));
  }

  void _showInviteCode(Invite invite) {
    showDialog<void>(
      context: context,
      builder: (_) => InviteCreatedDialog(invite: invite),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: _buildBody(),
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              onPressed: _isWorking ? null : _inviteMember,
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Invite'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return _MembersError(message: error, onRetry: _load);
    }

    final theme = Theme.of(context);
    final organizerCount = _members
        .where((member) => member.role == MemberRole.organizer)
        .length;
    final now = DateTime.now();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text(widget.fundName, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'People with access to this ledger.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Members', count: _members.length),
        const SizedBox(height: 8),
        for (final member in _members)
          _MemberTile(
            member: member,
            isCurrentUser: member.userId == widget.currentUserId,
            isLastOrganizer:
                member.role == MemberRole.organizer && organizerCount == 1,
            canManage: _canManage,
            onRoleChanged: (role) => _changeRole(member, role),
            onRemove: () => _removeMember(member),
          ),
        if (_canManage && _invites.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionHeader(title: 'Pending invites', count: _invites.length),
          const SizedBox(height: 8),
          for (final invite in _invites)
            _InviteTile(
              invite: invite,
              isExpired: invite.isExpiredAt(now),
              onShowCode: () => _showInviteCode(invite),
              onCancel: () => _cancelInvite(invite),
            ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isCurrentUser,
    required this.isLastOrganizer,
    required this.canManage,
    required this.onRoleChanged,
    required this.onRemove,
  });

  final Membership member;
  final bool isCurrentUser;
  final bool isLastOrganizer;
  final bool canManage;
  final ValueChanged<MemberRole> onRoleChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = member.displayName + (isCurrentUser ? ' (you)' : '');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text(_initial(member.displayName))),
        title: Text(name, overflow: TextOverflow.ellipsis),
        subtitle: Text(member.role.label),
        trailing: !canManage
            ? null
            : isLastOrganizer
            ? Tooltip(
                message: 'A fund must keep at least one organizer',
                child: Icon(
                  Icons.lock_outline,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : PopupMenuButton<_MemberAction>(
                tooltip: 'Manage ${member.displayName}',
                onSelected: (action) => _handleAction(action),
                itemBuilder: (context) => [
                  for (final role in MemberRole.values)
                    if (role != member.role)
                      PopupMenuItem<_MemberAction>(
                        value: _actionFor(role),
                        child: Text('Change to ${role.label}'),
                      ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<_MemberAction>(
                    value: _MemberAction.remove,
                    child: Text('Remove from fund'),
                  ),
                ],
              ),
      ),
    );
  }

  void _handleAction(_MemberAction action) {
    switch (action) {
      case _MemberAction.makeOrganizer:
        onRoleChanged(MemberRole.organizer);
      case _MemberAction.makeMember:
        onRoleChanged(MemberRole.member);
      case _MemberAction.makeObserver:
        onRoleChanged(MemberRole.observer);
      case _MemberAction.remove:
        onRemove();
    }
  }

  static _MemberAction _actionFor(MemberRole role) {
    return switch (role) {
      MemberRole.organizer => _MemberAction.makeOrganizer,
      MemberRole.member => _MemberAction.makeMember,
      MemberRole.observer => _MemberAction.makeObserver,
    };
  }

  static String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }
}

class _InviteTile extends StatelessWidget {
  const _InviteTile({
    required this.invite,
    required this.isExpired,
    required this.onShowCode,
    required this.onCancel,
  });

  final Invite invite;
  final bool isExpired;
  final VoidCallback onShowCode;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expires = MaterialLocalizations.of(context)
        .formatShortDate(invite.expiresAt.toLocal());
    final detail = isExpired
        ? '${invite.role.label} · expired $expires'
        : '${invite.role.label} · expires $expires';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.mail_outline),
        title: Text(invite.email, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          detail,
          style: isExpired
              ? theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                )
              : null,
        ),
        onTap: onShowCode,
        trailing: IconButton(
          onPressed: onCancel,
          tooltip: 'Cancel invite',
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }
}

class _MembersError extends StatelessWidget {
  const _MembersError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('Could not load members', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
