import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:formatic/core/theme/button_styles.dart';
import 'package:formatic/core/utils/snackbar_utils.dart';
import 'package:formatic/features/auth/pages/login_page.dart';
import 'package:formatic/features/home/widgets/app_top_nav_bar.dart';
// bottom nav removed from profile per UI update
import 'package:formatic/models/auth/user_profile.dart';
import 'package:formatic/services/auth/auth_service.dart';
import 'package:formatic/services/profile/profile_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Formatter to enforce digits-only input and format as (xx) xxxxx-xxxx
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted = '';
    if (digits.isEmpty) return newValue.copyWith(text: '');

    // Build (xx) xxxxx-xxxx
    if (digits.length <= 2) {
      formatted = '(${digits.substring(0, digits.length)}';
    } else if (digits.length <= 7) {
      formatted = '(${digits.substring(0, 2)}) ${digits.substring(2)}';
    } else if (digits.length <= 11) {
      final part1 = digits.substring(0, 2);
      final part2 = digits.substring(2, digits.length <= 7 ? digits.length : 7);
      final part3 = digits.length > 7 ? digits.substring(7) : '';
      formatted = '($part1) $part2${part3.isNotEmpty ? '-$part3' : ''}';
    } else {
      // Limit to 11 digits
      final d = digits.substring(0, 11);
      final part1 = d.substring(0, 2);
      final part2 = d.substring(2, 7);
      final part3 = d.substring(7);
      formatted = '($part1) $part2-$part3';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Avatar picking will be handled via ImagePicker and persisted locally (SharedPreferences)

class ProfilePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  const ProfilePage({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  double _avatarScale = 1.0;

  Future<void> _onAvatarTap() async {
    // small press animation, then open picker
    setState(() => _avatarScale = 0.95);
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    setState(() => _avatarScale = 1.0);
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    await _pickAvatar();
  }

  Widget _profileCard(BuildContext context) {
    final isDark = widget.isDarkMode;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color labelColor = isDark ? Colors.white70 : Colors.grey;
    final Color iconColor = const Color(0xFF8B2CF5);
    final Color mainProfileColor = const Color(0xFF8B2CF5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        _profileInfoRow(
          Icons.email,
          'Email',
          _email ?? '',
          textColor,
          labelColor,
          iconColor,
        ),
        const SizedBox(height: 12),
        _profileInfoRow(
          Icons.phone_android,
          'Telefone',
          _phoneController.text.isEmpty
              ? 'Telefone não inserido'
              : _phoneController.text,
          textColor,
          labelColor,
          iconColor,
        ),
        const SizedBox(height: 16),
        _profileInfoRow(
          Icons.calendar_today,
          'Criado em',
          _createdAt ?? '',
          textColor,
          labelColor,
          iconColor,
        ),
        const SizedBox(height: 8),
        _profileInfoRow(
          Icons.update,
          'Atualizado em',
          _updatedAt ?? '',
          textColor,
          labelColor,
          iconColor,
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            icon: Icon(Icons.edit, color: mainProfileColor),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Adicionar / Editar telefone',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: mainProfileColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _showEditPhoneDialog,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _confirmDeleteProfile(context),
            child: const Text(
              'Deletar perfil',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
  // _profileField removed; phone is displayed with _profileInfoRow and edited via dialog

  Widget _profileInfoRow(
    IconData icon,
    String label,
    String value,
    Color textColor,
    Color labelColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '-' : value,
                  style: TextStyle(
                    fontSize: 18,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _uid;
  String? _email;
  String? _avatarUrl;
  String? _createdAt;
  String? _updatedAt;
  bool _loading = true;
  // phone editing handled via dialog
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // (removed profile background color persistence)

  Future<void> _saveProfile() async {
    setState(() => _loading = true);

    try {
      final user = AuthService().currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      // Criar perfil atualizado
      final updatedProfile = UserProfile(
        id: user.id,
        username: _nameController.text.trim(),
        email: _email ?? user.email ?? '',
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        createdAt: DateTime.parse(
          _createdAt?.split(' ')[0].split('/').reversed.join('-') ??
              DateTime.now().toIso8601String(),
        ),
      );

      // Salvar no backend (nota: o ProfileService não tem método update, então criamos um novo)
      final profileService = ProfileService();
      await profileService.createProfile(updatedProfile);

      setState(() => _loading = false);
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, 'Perfil atualizado!');
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Erro ao atualizar perfil: $e');
    }
  }

  // Avatar handling: save/load local path in SharedPreferences and pick from gallery
  Future<void> _saveAvatarPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_avatar_path', path);
  }

  Future<void> _pickAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file != null) {
        // Show local preview immediately
        setState(() {
          _avatarUrl = file.path;
        });
        await _saveAvatarPath(file.path);

        // Attempt to upload to Supabase Storage and update profile record
        try {
          final profileService = ProfileService();
          final user = AuthService().currentUser;
          if (user != null) {
            final uploadedUrl = await profileService.uploadAvatarFile(
              File(file.path),
              user.id,
            );
            if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
              // update remote profile with avatar URL
              await profileService.patchProfile(user.id, {
                'avatar_url': uploadedUrl,
              });
              // prefer the remote URL for display
              if (mounted) {
                setState(() => _avatarUrl = uploadedUrl);
              }
            }
          }
        } catch (e) {
          if (mounted) {
            SnackbarUtils.showError(
              context,
              'Aviso: avatar salvo localmente, upload falhou: $e',
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Erro ao selecionar imagem: $e');
    }
  }

  Future<void> _showEditPhoneDialog() async {
    final controller = TextEditingController(text: _phoneController.text);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Editar telefone'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              PhoneNumberFormatter(),
            ],
            decoration: const InputDecoration(labelText: 'Telefone'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: purpleElevatedStyle(),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() => _phoneController.text = controller.text);
      await _saveProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context); // Não utilizado
    final isDark = widget.isDarkMode;
    final Color mainColor = const Color(0xFF8B2CF5);
    final Color cardColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    return Scaffold(
      appBar: AppTopNavBar(
        title: 'Perfil',
        isDarkMode: widget.isDarkMode,
        onThemeToggle: widget.onThemeToggle,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A1B2E),
                    const Color(0xFF533483),
                    const Color(0xFF8B2CF5),
                  ]
                : [
                    const Color.fromARGB(255, 155, 30, 233),
                    const Color(0xFF9C27B0),
                    const Color(0xFF673AB7),
                  ],
          ),
        ),
        child: Column(
          children: [
            // Seção superior com avatar circular e UID acima do nome
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Animated pulse on tap
                        AnimatedScale(
                          scale: _avatarScale,
                          duration: const Duration(milliseconds: 120),
                          child: GestureDetector(
                            onTap: _onAvatarTap,
                            child: CircleAvatar(
                              radius: 70,
                              backgroundColor: Colors.white,
                              child: ClipOval(
                                child:
                                    _avatarUrl != null && _avatarUrl!.isNotEmpty
                                    ? (_avatarUrl!.startsWith('http')
                                          ? Image.network(
                                              _avatarUrl!,
                                              fit: BoxFit.cover,
                                              width: 140,
                                              height: 140,
                                            )
                                          : Image.file(
                                              File(_avatarUrl!),
                                              fit: BoxFit.cover,
                                              width: 140,
                                              height: 140,
                                            ))
                                    : Icon(
                                        Icons.person,
                                        size: 56,
                                        color: mainColor,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -6,
                          bottom: -6,
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 4,
                            child: IconButton(
                              icon: Icon(
                                Icons.camera_alt_outlined,
                                color: mainColor,
                              ),
                              onPressed: _onAvatarTap,
                              tooltip: 'Alterar avatar',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_uid != null && _uid!.isNotEmpty)
                    Text(
                      _uid!,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  const SizedBox(height: 6),
                  // Nome centralizado abaixo da foto (menor)
                  Text(
                    _nameController.text.isEmpty
                        ? 'Usuário'
                        : _nameController.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Seção inferior com card
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _profileCard(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);

    try {
      final user = AuthService().currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      // Tentar carregar perfil do backend
      final profileService = ProfileService();
      UserProfile? profile;

      try {
        profile = await profileService.getProfile(user.id);
      } catch (e) {
        // Se não encontrar perfil, criar um padrão
        profile = UserProfile(
          id: user.id,
          username: user.email!.split('@')[0],
          email: user.email!,
          createdAt: DateTime.now(),
        );
      }

      setState(() {
        _uid = profile!.id;
        _email = profile.email;
        _nameController.text = profile.username;
        _phoneController.text = profile.phone ?? '';
        _avatarUrl = profile.avatarUrl;
        _createdAt =
            '${profile.createdAt.day}/${profile.createdAt.month}/${profile.createdAt.year} ${profile.createdAt.hour}:${profile.createdAt.minute.toString().padLeft(2, '0')}';
        _updatedAt =
            '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
      });
      // Prefer a locally saved avatar path if present
      final prefs = await SharedPreferences.getInstance();
      final localPath = prefs.getString('profile_avatar_path');
      if (localPath != null && localPath.isNotEmpty) {
        setState(() => _avatarUrl = localPath);
      }
    } catch (e) {
      // Em caso de erro, usar dados padrão
      if (mounted) {
        setState(() {
          _uid = "erro-carregamento";
          _email = "erro@exemplo.com";
          _nameController.text = "Erro no carregamento";
          _phoneController.text = "";
          _avatarUrl = null;
          final now = DateTime.now();
          _createdAt =
              '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
          _updatedAt =
              '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
        });
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmDeleteProfile(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Deletar perfil'),
          content: const Text(
            'Tem certeza de que deseja deletar seu perfil? Esta ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Não'),
            ),
            ElevatedButton(
              style: purpleElevatedStyle(),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sim'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (!mounted) return;
      await _deleteProfileAndSignOut();
    }
  }

  Future<void> _deleteProfileAndSignOut() async {
    if (_uid == null) return;
    setState(() => _loading = true);
    // capture navigator before async gaps to avoid using BuildContext across awaits
    final navigator = Navigator.of(context);
    try {
      final profileService = ProfileService();
      await profileService.deleteProfile(_uid!);
      await AuthService().signOut();
      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginPage(onThemeToggle: widget.onThemeToggle),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Erro ao deletar perfil: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
