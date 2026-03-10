import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../data/dtos/user_dtos.dart';
import '../domain/users_providers.dart';

/// Página CRUD de usuários admin — Etapa 13.
class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersListProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminManageUsers),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            tooltip: l10n.reload,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(usersListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: Text(l10n.adminUsersNewUser),
        onPressed: () => _showCreateDialog(context, ref),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          fallbackMessage: l10n.adminUsersLoadError,
          onRetry: () => ref.invalidate(usersListProvider),
        ),
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Text(l10n.adminUsersEmpty),
            );
          }
          return _UsersList(users: users);
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => _UserFormDialog(
        title: l10n.adminUsersCreateTitle,
        onSave: (email, password, role) async {
          final datasource = ref.read(usersDatasourceProvider);
          await datasource.create(
            UserCreateDto(email: email, password: password!, role: role),
          );
          ref.invalidate(usersListProvider);
        },
      ),
    );
  }
}



// ─── Users List ───

class _UsersList extends ConsumerWidget {
  const _UsersList({required this.users});

  final List<UserDto> users;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final l10n = AppLocalizations.of(context)!;

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      itemCount: users.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = users[index];
        final isAdmin = user.role.toLowerCase() == 'admin';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                isAdmin ? colorScheme.errorContainer : colorScheme.primaryContainer,
            child: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.person,
              color: isAdmin
                  ? colorScheme.onErrorContainer
                  : colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(user.email),
          subtitle: Text(
            '${user.role} • ${l10n.adminUsersCreatedAt(dateFormat.format(user.createdAtUtc.toLocal()))}',
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'edit') {
                _showEditDialog(context, ref, user);
              } else if (action == 'delete') {
                _showDeleteDialog(context, ref, user);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: const Icon(Icons.edit),
                  title: Text(l10n.edit),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, UserDto user) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => _UserFormDialog(
        title: l10n.adminUsersEditTitle,
        initialEmail: user.email,
        initialRole: user.role,
        isEdit: true,
        onSave: (email, password, role) async {
          final datasource = ref.read(usersDatasourceProvider);
          await datasource.update(
            user.id,
            UserUpdateDto(
              email: email != user.email ? email : null,
              password: password?.isNotEmpty == true ? password : null,
              role: role != user.role ? role : null,
            ),
          );
          ref.invalidate(usersListProvider);
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, UserDto user) {
    showDialog(
      context: context,
      builder: (_) => _DeleteConfirmDialog(
        user: user,
        onConfirm: () async {
          final datasource = ref.read(usersDatasourceProvider);
          await datasource.delete(user.id);
          ref.invalidate(usersListProvider);
        },
      ),
    );
  }
}

// ─── User Form Dialog (Create / Edit) ───

class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({
    required this.title,
    required this.onSave,
    this.initialEmail,
    this.initialRole,
    this.isEdit = false,
  });

  final String title;
  final Future<void> Function(String email, String? password, String role) onSave;
  final String? initialEmail;
  final String? initialRole;
  final bool isEdit;

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late String _selectedRole;

  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _passwordController = TextEditingController();
    _selectedRole = widget.initialRole ?? 'User';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    // Na edição, verifica se ao menos um campo mudou.
    if (widget.isEdit) {
      final emailChanged = _emailController.text.trim() != widget.initialEmail;
      final passwordFilled = _passwordController.text.isNotEmpty;
      final roleChanged = _selectedRole != widget.initialRole;
      if (!emailChanged && !passwordFilled && !roleChanged) {
        Navigator.of(context).pop();
        return;
      }
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await widget.onSave(
        _emailController.text.trim(),
        _passwordController.text.isNotEmpty ? _passwordController.text : null,
        _selectedRole,
      );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() {
        if (e.statusCode == 409 || e.message.contains('já existe')) {
          _errorMessage = l10n.registerEmailExists;
        } else if (e.type == ApiExceptionType.rateLimit) {
          _errorMessage = l10n.rateLimitErrorShort;
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Theme.of(context).colorScheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.adminUsersEmailRequired;
                  }
                  if (!value.contains('@')) {
                    return l10n.invalidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: widget.isEdit
                      ? l10n.adminUsersNewPassword
                      : l10n.password,
                  prefixIcon: const Icon(Icons.lock_outlined),
                ),
                obscureText: true,
                validator: (value) {
                  if (!widget.isEdit &&
                      (value == null || value.isEmpty)) {
                    return l10n.adminUsersPasswordRequired;
                  }
                  if (value != null &&
                      value.isNotEmpty &&
                      value.length < 6) {
                    return l10n.passwordMinLength;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: InputDecoration(
                  labelText: l10n.adminUsersRole,
                  prefixIcon: const Icon(Icons.shield_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'User', child: Text('User')),
                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRole = value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save),
          label: Text(widget.isEdit ? l10n.save : l10n.create),
          onPressed: _loading ? null : _submit,
        ),
      ],
    );
  }
}

// ─── Delete Confirmation Dialog ───

class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog({
    required this.user,
    required this.onConfirm,
  });

  final UserDto user;
  final Future<void> Function() onConfirm;

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  bool _loading = false;
  String? _errorMessage;

  Future<void> _handleDelete() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await widget.onConfirm();
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.adminUsersDeleteTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: colorScheme.error, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(l10n.adminUsersDeleteConfirm),
          const SizedBox(height: 8),
          Text(
            widget.user.email,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.adminUsersDeleteRole(widget.user.role),
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.adminUsersDeleteWarning,
            style: TextStyle(color: colorScheme.error, fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.delete),
          label: Text(l10n.delete),
          onPressed: _loading ? null : _handleDelete,
        ),
      ],
    );
  }
}

