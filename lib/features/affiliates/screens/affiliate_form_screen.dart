import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/core/providers/connectivity_provider.dart';
import 'package:modus_pampa_v3/core/providers/theme_provider.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/features/affiliates/providers/affiliate_providers.dart';
import 'package:modus_pampa_v3/features/attendance/providers/attendance_providers.dart';
import 'package:modus_pampa_v3/features/contributions/providers/contribution_providers.dart';
import 'package:modus_pampa_v3/features/fines/providers/fines_providers.dart';
import 'package:modus_pampa_v3/features/reports/providers/pdf_service_provider.dart';
import 'package:modus_pampa_v3/features/reports/screens/pdf_viewer_screen.dart';
import 'package:modus_pampa_v3/features/settings/providers/cloudinary_provider.dart';
import 'package:modus_pampa_v3/shared/utils/validators.dart';
import 'package:speed_dial_fab/speed_dial_fab.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AffiliateFormScreen extends ConsumerStatefulWidget {
  final Affiliate? affiliate;
  final bool isGuestMode;

  const AffiliateFormScreen({
    super.key,
    this.affiliate,
    this.isGuestMode = false,
  });

  @override
  ConsumerState<AffiliateFormScreen> createState() =>
      _AffiliateFormScreenState();
}

class _AffiliateFormScreenState extends ConsumerState<AffiliateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _ciController;
  late final TextEditingController _phoneController;
  late final TextEditingController _originalAffiliateController;
  late final TextEditingController _currentAffiliateController;
  late final TextEditingController _tagsController;
  XFile? _profileImageFile;
  XFile? _credentialImageFile;
  bool get isEditing => widget.affiliate != null && !widget.isGuestMode;
  bool _isGeneratingReport = false;

  @override
  void initState() {
    super.initState();
    final affiliate = widget.affiliate;
    _idController = TextEditingController(text: affiliate?.id ?? '');
    _firstNameController = TextEditingController(
      text: affiliate?.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: affiliate?.lastName ?? '',
    );
    _ciController = TextEditingController(text: affiliate?.ci ?? '');
    _phoneController = TextEditingController(text: affiliate?.phone ?? '');
    _originalAffiliateController = TextEditingController(
      text: affiliate?.originalAffiliateName ?? '-',
    );
    _currentAffiliateController = TextEditingController(
      text: affiliate?.currentAffiliateName ?? '-',
    );
    _tagsController = TextEditingController(
      text: affiliate?.tags.join(', ') ?? '',
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ciController.dispose();
    _phoneController.dispose();
    _originalAffiliateController.dispose();
    _currentAffiliateController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(
    ImageSource source,
    Function(XFile) onImagePicked,
  ) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        onImagePicked(image);
      });
    }
  }

  void _showImagePicker(Function(XFile) onImagePicked) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galería de fotos'),
                  onTap: () {
                    _pickImage(ImageSource.gallery, onImagePicked);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Cámara'),
                  onTap: () {
                    _pickImage(ImageSource.camera, onImagePicked);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        // 1. Envolvemos el AlertDialog con un StatefulBuilder para manejar el estado de carga
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Confirmar Eliminación'),
              content: Text(
                '¿Está seguro de que desea eliminar a ${widget.affiliate!.fullName}?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  // 2. Deshabilitamos el botón y mostramos el indicador si se está eliminando
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setState(() {
                            isDeleting = true;
                          });
                          await ref
                              .read(affiliateOperationProvider.notifier)
                              .deleteAffiliate(widget.affiliate!.uuid);
                          if (mounted) {
                            Navigator.of(dialogContext).pop(); // Cierra el diálogo
                            context.pop(); // Regresa a la lista
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ))
                      : const Text('Eliminar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveAffiliate() async {
    if (_formKey.currentState!.validate()) {

      // Muestra un indicador de carga mientras se procesa
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      
      final connectivityResult = await ref.read(connectivityStreamProvider.future);
      final isOnline = connectivityResult.contains(ConnectivityResult.mobile) || connectivityResult.contains(ConnectivityResult.wifi);
      
      String? finalProfileUrl = widget.affiliate?.profilePhotoUrl;
      String? finalCredentialUrl = widget.affiliate?.credentialPhotoUrl;

      try {
        // --- LÓGICA DE SUBIDA DE IMÁGENES ---
        if (isOnline) {
          final cloudinaryService = ref.read(cloudinaryServiceProvider);
          if (_profileImageFile != null) {
            finalProfileUrl = await cloudinaryService.uploadImage(_profileImageFile!);
          }
          if (_credentialImageFile != null) {
            finalCredentialUrl = await cloudinaryService.uploadImage(_credentialImageFile!);
          }
        } else {
          // Si está offline, simplemente guarda la ruta local del archivo
          if (_profileImageFile != null) {
            finalProfileUrl = _profileImageFile!.path;
          }
          if (_credentialImageFile != null) {
            finalCredentialUrl = _credentialImageFile!.path;
          }
        }

      final notifier = ref.read(affiliateOperationProvider.notifier);
      final tags =
          _tagsController.text
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList();
      late final Affiliate affiliateToSave;
      if (isEditing) {
        affiliateToSave = widget.affiliate!.copyWith(
          id: _idController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          ci: _ciController.text.trim(),
          phone: _phoneController.text.trim(),
          originalAffiliateName: _originalAffiliateController.text.trim(),
          currentAffiliateName: _currentAffiliateController.text.trim(),
          tags: tags,
          profilePhotoUrl: finalProfileUrl,
          credentialPhotoUrl: finalCredentialUrl,
        );
      } else {
        affiliateToSave = Affiliate(
          uuid: const Uuid().v4(),
          id: _idController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          ci: _ciController.text.trim(),
          phone: _phoneController.text.trim(),
          originalAffiliateName: _originalAffiliateController.text.trim(),
          currentAffiliateName: _currentAffiliateController.text.trim(),
          tags: tags,
          profilePhotoUrl: finalProfileUrl,
          credentialPhotoUrl: finalCredentialUrl,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      bool success = false;
      if (isEditing) {
        success = await notifier.updateAffiliate(affiliateToSave);
      } else {
        success = await notifier.createAffiliate(affiliateToSave);
      }
      if (success && mounted) {
        context.pop();
      }
      } catch (e) {
        Navigator.of(context).pop(); // Cierra el loader en caso de error
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al guardar: $e"), backgroundColor: Colors.red));
      }
    
    }
  }

  Future<void> _generateAndShowReport({
    required String title,
    required Future<Uint8List> Function() generator,
  }) async {
    setState(() {
      _isGeneratingReport = true;
    });
    try {
      final pdfData = await generator();
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(pdfData: pdfData, title: title),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al generar reporte: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.read(themeNotifierProvider.notifier);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AffiliateOperationState>(affiliateOperationProvider, (
      previous,
      next,
    ) {
      if (next is AffiliateOperationSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
      if (next is AffiliateOperationError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });
    final state = ref.watch(affiliateOperationProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isGuestMode
              ? 'Mi Perfil'
              : (isEditing ? 'Editar Afiliado' : 'Nuevo Afiliado'),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
          if (widget.isGuestMode)
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              onPressed: () {
                themeNotifier.toggleTheme();
              },
            ),
        ],
      ),
      drawer: widget.isGuestMode ? _buildGuestDrawer(context) : null,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap:
                        widget.isGuestMode
                            ? null
                            : () => _showImagePicker(
                              (image) => _profileImageFile = image,
                            ),
                    child: Center(
                      child: _buildCircularImage(context),
                    ).animate().fade().scale(delay: 200.ms),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Datos Personales'),
                  TextFormField(
                    controller: _idController,
                    enabled: !widget.isGuestMode,
                    decoration: const InputDecoration(
                      labelText: 'ID Afiliado (ej: AP-001)',
                    ),
                    validator: (value) => Validators.notEmpty(value, 'ID'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _firstNameController,
                    enabled: !widget.isGuestMode,
                    decoration: const InputDecoration(labelText: 'Nombres'),
                    validator: (value) => Validators.notEmpty(value, 'Nombres'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lastNameController,
                    enabled: !widget.isGuestMode,
                    decoration: const InputDecoration(labelText: 'Apellidos'),
                    validator:
                        (value) => Validators.notEmpty(value, 'Apellidos'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ciController,
                    enabled: !widget.isGuestMode,
                    decoration: const InputDecoration(
                      labelText: 'Carnet de Identidad (CI)',
                    ),
                    validator: (value) => Validators.notEmpty(value, 'CI'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    enabled: !widget.isGuestMode,
                    decoration: const InputDecoration(
                      labelText: 'Celular (Opcional)',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Datos de Afiliación'),
                  TextFormField(
                    controller: _originalAffiliateController,
                    enabled: !widget.isGuestMode,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Afiliado Original',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _currentAffiliateController,
                    enabled: !widget.isGuestMode,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Afiliado Actual',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tagsController,
                    enabled: !widget.isGuestMode,
                    decoration: const InputDecoration(
                      labelText: 'Tags (separados por coma)',
                      hintText: 'Ej: fundador, directiva, activo',
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!widget.isGuestMode) ...[
                    _buildSectionTitle(context, 'Credencial'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap:
                          () => _showImagePicker(
                            (image) => _credentialImageFile = image,
                          ),
                      child: _buildRectangularImage(context),
                    ),
                    const SizedBox(height: 32),
                  ],
                  if (widget.isGuestMode)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Salir del Modo Invitado'),
                        onPressed: () => context.go('/login'),
                      ),
                    ),
                  if (!widget.isGuestMode)
                    if (state is AffiliateOperationLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton.icon(
                        onPressed: _saveAffiliate,
                        icon: const Icon(Icons.save),
                        label: const Text('GUARDAR'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (_isGeneratingReport)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton:
          (isEditing || widget.isGuestMode) ? _buildSpeedDial() : null,
    );
  }

  Widget _buildGuestDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              widget.affiliate?.fullName ?? "Afiliado",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: const Text("Modo Invitado"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.onPrimary,
              child: Icon(
                Icons.person,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Salir'),
            onTap: () {
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDial() {
    return SpeedDialFabWidget(
      secondaryIconsList: const [
        Icons.description,
        Icons.receipt_long,
        Icons.money_off,
        Icons.checklist,
      ],
      secondaryIconsText: const ["Resumen", "Aportes", "Multas", "Asistencias"],
      secondaryIconsOnPress: [
        () => _generateAndShowReport(
          title: "Reporte de Resumen",
          generator: () async {
            final pdfService = ref.read(pdfServiceProvider);
            final fines = await ref.read(
              finesByAffiliateProvider(widget.affiliate!.uuid).future,
            );
            final contributions = await ref.read(
              pendingContributionsProvider(widget.affiliate!.uuid).future,
            );
            return pdfService.generateAffiliateSummaryReport(
              affiliate: widget.affiliate!,
              fines: fines,
              contributions: contributions,
            );
          },
        ),
        () => _generateAndShowReport(
          title: "Reporte de Aportes",
          generator: () async {
            final pdfService = ref.read(pdfServiceProvider);
            final links = await ref.read(
              allContributionsByAffiliateProvider(
                widget.affiliate!.uuid,
              ).future,
            );
            final allContributions = await ref.read(
              contributionListProvider.future,
            );
            return pdfService.generateAffiliateContributionsReport(
              affiliate: widget.affiliate!,
              links: links,
              allContributions: allContributions,
            );
          },
        ),
        () => _generateAndShowReport(
          title: "Reporte de Multas",
          generator: () async {
            final pdfService = ref.read(pdfServiceProvider);
            final fines = await ref.read(
              finesByAffiliateProvider(widget.affiliate!.uuid).future,
            );
            return pdfService.generateAffiliateFinesReport(
              affiliate: widget.affiliate!,
              fines: fines,
            );
          },
        ),
        () => _generateAndShowReport(
          title: "Reporte de Asistencias",
          generator: () async {
            final pdfService = ref.read(pdfServiceProvider);
            final records = await ref.read(
              allAttendanceByAffiliateProvider(widget.affiliate!.uuid).future,
            );
            final allLists = await ref.read(attendanceListProvider.future);
            return pdfService.generateAffiliateAttendanceReport(
              affiliate: widget.affiliate!,
              records: records,
              allLists: allLists,
            );
          },
        ),
      ],
      primaryIconExpand: Icons.picture_as_pdf,
      primaryIconCollapse: Icons.close,
      secondaryBackgroundColor: Theme.of(context).colorScheme.secondary,
      primaryBackgroundColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildCircularImage(BuildContext context) {
    ImageProvider? imageProvider;
    if (_profileImageFile != null) {
      if (kIsWeb) {
        imageProvider = NetworkImage(_profileImageFile!.path);
      } else {
        imageProvider = FileImage(File(_profileImageFile!.path));
      }
    } else if (widget.affiliate?.profilePhotoUrl != null) {
      if (kIsWeb) {
        // En web, asumir que todas las URLs son de red
        imageProvider = CachedNetworkImageProvider(
          widget.affiliate!.profilePhotoUrl!,
        );
      } else {
        // En plataformas nativas, verificar si es archivo local
        if (File(widget.affiliate!.profilePhotoUrl!).existsSync()) {
          imageProvider = FileImage(File(widget.affiliate!.profilePhotoUrl!));
        } else {
          imageProvider = CachedNetworkImageProvider(
            widget.affiliate!.profilePhotoUrl!,
          );
        }
      }
    }
    return CircleAvatar(
      radius: 70,
      backgroundColor: Theme.of(context).colorScheme.surface,
      backgroundImage: imageProvider,
      child:
          imageProvider == null
              ? Icon(Icons.camera_alt, color: Colors.grey.shade600, size: 50)
              : null,
    );
  }

  Widget _buildRectangularImage(BuildContext context) {
    ImageProvider? imageProvider;
    if (_credentialImageFile != null) {
      if (kIsWeb) {
        imageProvider = NetworkImage(_credentialImageFile!.path);
      } else {
        imageProvider = FileImage(File(_credentialImageFile!.path));
      }
    } else if (widget.affiliate?.credentialPhotoUrl != null) {
      if (kIsWeb) {
        // En web, asumir que todas las URLs son de red
        imageProvider = CachedNetworkImageProvider(
          widget.affiliate!.credentialPhotoUrl!,
        );
      } else {
        // En plataformas nativas, verificar si es archivo local
        if (File(widget.affiliate!.credentialPhotoUrl!).existsSync()) {
          imageProvider = FileImage(File(widget.affiliate!.credentialPhotoUrl!));
        } else {
          imageProvider = CachedNetworkImageProvider(
            widget.affiliate!.credentialPhotoUrl!,
          );
        }
      }
    }
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          image:
              imageProvider != null
                  ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                  : null,
          border: Border.all(
            color: Colors.grey.shade400,
            style: BorderStyle.solid,
          ),
        ),
        child:
            imageProvider == null
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      color: Colors.grey.shade600,
                      size: 50,
                    ),
                    const SizedBox(height: 8),
                    const Text('Imagen del Credencial'),
                  ],
                )
                : null,
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
