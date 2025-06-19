import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/data/models/user_model.dart';
import 'package:modus_pampa_v3/features/auth/providers/auth_providers.dart';
import 'package:modus_pampa_v3/features/settings/providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _lateFineController;
  late final TextEditingController _absentFineController;
  late final TextEditingController _backendUrlController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsServiceProvider);
    _lateFineController = TextEditingController(text: settings.getFineAmountLate().toString());
    _absentFineController = TextEditingController(text: settings.getFineAmountAbsent().toString());
    _backendUrlController = TextEditingController(text: settings.getBackendUrl());
  }

  @override
  void dispose() {
    _lateFineController.dispose();
    _absentFineController.dispose();
    _backendUrlController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final settings = ref.read(settingsServiceProvider);
      settings.setFineAmountLate(double.tryParse(_lateFineController.text) ?? 5.0);
      settings.setFineAmountAbsent(double.tryParse(_absentFineController.text) ?? 20.0);
      settings.setBackendUrl(_backendUrlController.text);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración guardada.'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider) as Authenticated;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Valores de Multas', style: Theme.of(context).textTheme.titleLarge),
              TextFormField(controller: _lateFineController, decoration: const InputDecoration(labelText: 'Monto por Retraso (Bs.)'), keyboardType: TextInputType.number),
              TextFormField(controller: _absentFineController, decoration: const InputDecoration(labelText: 'Monto por Falta (Bs.)'), keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              Text('Conectividad', style: Theme.of(context).textTheme.titleLarge),
              TextFormField(controller: _backendUrlController, decoration: const InputDecoration(labelText: 'URL del Backend')),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveSettings, child: const Text('Guardar Configuración'))),
              const Divider(height: 40),
              
              if (currentUser.user.role == UserRole.superAdmin) ...[
                Text('Gestión de Usuarios', style: Theme.of(context).textTheme.titleLarge),
                _buildUserManagementSection(),
              ],

              const Divider(height: 40),
              Text('Operaciones Pendientes', style: Theme.of(context).textTheme.titleLarge),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Sincronizar con el servidor'),
                subtitle: const Text('0 operaciones pendientes'), // Placeholder
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sincronizando...')));
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserManagementSection() {
    final allUsersAsync = ref.watch(allUsersProvider);
    final currentUser = (ref.read(authStateProvider) as Authenticated).user;

    return allUsersAsync.when(
      data: (users) => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          // El SuperAdmin no puede cambiarse el rol a sí mismo
          if (user.uuid == currentUser.uuid) return const SizedBox.shrink();

          return Card(
            child: ListTile(
              title: Text(user.userName),
              subtitle: Text(user.email),
              trailing: DropdownButton<UserRole>(
                value: user.role,
                items: UserRole.values.map((role) {
                  return DropdownMenuItem(value: role, child: Text(role.name));
                }).toList(),
                onChanged: (newRole) {
                  if (newRole != null) {
                    ref.read(authStateProvider.notifier).updateUserRole(user.uuid, newRole).then((_) {
                       ref.invalidate(allUsersProvider); // Refresca la lista de usuarios
                    });
                  }
                },
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error al cargar usuarios: $e'),
    );
  }
}
