import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/data/models/configuration_model.dart';
import 'package:modus_pampa_v3/data/models/user_model.dart';
import 'package:modus_pampa_v3/features/auth/providers/auth_providers.dart';
import 'package:modus_pampa_v3/features/settings/providers/settings_provider.dart';
import 'package:modus_pampa_v3/features/settings/screens/pending_operations_screen.dart';
import 'package:modus_pampa_v3/features/settings/services/sync_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _lateFineController;
  late TextEditingController _absentFineController;
  late TextEditingController _backendUrlController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Inicialización simple, los valores se cargarán en didChangeDependencies.
    _lateFineController = TextEditingController();
    _absentFineController = TextEditingController();
    _backendUrlController = TextEditingController();
  }

  // --- 1. USA didChangeDependencies PARA ACTUALIZAR LOS CONTROLLERS ---
  // Este método se llama cuando las dependencias del widget cambian.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Observamos los nuevos providers.
    final lateFine = ref.watch(lateFineAmountProvider);
    final absentFine = ref.watch(absentFineAmountProvider);
    final backendUrl = ref.watch(backendUrlProvider);

    // Actualizamos el texto de los controllers, que a su vez actualizan la UI.
    _lateFineController.text = lateFine.toString();
    _absentFineController.text = absentFine.toString();
    _backendUrlController.text = backendUrl;
  }

  @override
  void dispose() {
    _lateFineController.dispose();
    _absentFineController.dispose();
    _backendUrlController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final settingsToSave = AppSettings(
        montoMultaRetraso: double.tryParse(_lateFineController.text) ?? 5.0,
        montoMultaFalta: double.tryParse(_absentFineController.text) ?? 20.0,
        backendUrl: _backendUrlController.text,
      );

      final success = await ref.read(settingsServiceProvider).saveSettings(settingsToSave);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración guardada en el servidor.'), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar. Revisa la conexión.'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider) as Authenticated;
    final pendingOpsCount = ref.watch(pendingOperationsProvider).asData?.value.length ?? 0;
    
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
              Text('Sincronización', style: Theme.of(context).textTheme.titleLarge),
              ListTile(
                leading: Badge(
                  label: Text('$pendingOpsCount'),
                  isLabelVisible: pendingOpsCount > 0,
                  child: const Icon(Icons.sync_problem_outlined),
                ),
                title: const Text('Operaciones Pendientes'),
                subtitle: Text('$pendingOpsCount ${pendingOpsCount == 1 ? 'operación esperando' : 'operaciones esperando'} para sincronizar'),
                onTap: () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PendingOperationsScreen()));
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
