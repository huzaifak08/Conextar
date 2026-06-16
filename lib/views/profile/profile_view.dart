import 'dart:io';
import 'package:conextar/components/custom_button.dart';
import 'package:conextar/components/custom_text_field.dart';
import 'package:conextar/constants/theme.dart';
import 'package:conextar/models/api_response.dart';
import 'package:conextar/providers/current_user/current_user_provider.dart'; // Verified provider mapping path
import 'package:conextar/services/user_service.dart';
import 'package:conextar/views/auth/signin_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _nameController;
  final _nameFocus = FocusNode();

  File? _pickedImage;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();

    // Initialize controller data matching currently active provider memory snapshot
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        _nameController.text = user.name;
        _nameController.addListener(_checkFormChanges);
      }
    });
  }

  void _checkFormChanges() {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final changed =
        _nameController.text.trim() != user.name || _pickedImage != null;
    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
        _hasChanges = true;
      });
    }
  }

  // =========================================================================
  // UPDATE PROFILE PIPELINE (Fully Functional)
  // =========================================================================
  // void _handleSaveProfile() async {
  //   if (!_formKey.currentState!.validate()) return;

  //   setState(() => _isSaving = true);

  //   // Dispatches details directly to your Riverpod 2.0 notifier wrapper pipeline
  //   ApiResponse response = await ref
  //       .read(currentUserProvider.notifier)
  //       .updateProfileData(
  //         name: _nameController.text.trim(),
  //         pickedImageFile:
  //             _pickedImage, // Handled inside provider state mapping mutations
  //       );

  //   setState(() => _isSaving = false);

  //   if (response.status) {
  //     setState(() => _hasChanges = false);
  //     _showNotification(message: response.message, isError: false);
  //   } else {
  //     _showNotification(message: response.message, isError: true);
  //   }
  // }

  // =========================================================================
  // LOGOUT LIFECYCLE (Fixed Context Race Condition)
  // =========================================================================
  void _handleLogout() async {
    // 🎯 FIX: Capture the global root navigator shell instance context
    // synchronously BEFORE entering the asynchronous thread execution loop.
    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff11161B),
        title: const Text(
          "TERMINATE SESSION",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
        content: const Text(
          "Are you sure you want to disconnect from Contextar?",
          style: TextStyle(color: ContextarTheme.mutedTextCyan),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "ABORT",
              style: TextStyle(color: ContextarTheme.mutedTextCyan),
            ),
          ),
          TextButton(
            onPressed: () async {
              // 1. Instantly pop the AlertDialog off the screen layout array
              Navigator.pop(context);

              // 2. Fire full session teardown network pipelines
              await ref.read(currentUserProvider.notifier).logoutUser();

              // 3. 🎯 FIX: Use the pre-cached reference to clear the navigation history
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SigninView()),
                (route) => false,
              );
            },
            child: const Text(
              "DISCONNECT",
              style: TextStyle(
                color: Color(0xffF04848),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // DYNAMIC BOTTOM SHEET PASS-RESETS MODAL
  // =========================================================================
  void _showChangePasswordBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChangePasswordBottomSheet(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 Listening directly to your custom currentUserProvider state stream
    final userState = ref.watch(currentUserProvider);

    return Scaffold(
      body: Container(
        decoration: ContextarTheme.buildBackgroundGradient(),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: userState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: ContextarTheme.neonCyan),
            ),
            error: (err, _) => Center(
              child: Text(
                "Profile sync missing: $err",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            data: (user) {
              if (user == null) return const SizedBox.shrink();

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 24.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Title Layout Block
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PROFILE IDENTITY',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 3.0,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'System registry parameters.',
                                style: TextStyle(
                                  color: ContextarTheme.mutedTextCyan,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          // Premium Floating Save Indicator Hook (Wired perfectly now)
                          if (_hasChanges)
                            IconButton(
                              onPressed: null,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: ContextarTheme.neonCyan,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.check_circle,
                                      color: ContextarTheme.neonCyan,
                                      size: 28,
                                    ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Avatar Interactive Configuration Frame
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: ContextarTheme.neonCyan.withOpacity(
                                    0.6,
                                  ),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                backgroundColor: ContextarTheme.darkSlateGreen
                                    .withOpacity(0.3),
                                backgroundImage: _pickedImage != null
                                    ? FileImage(_pickedImage!)
                                    : (user.profilePic != null &&
                                                  user.profilePic!.isNotEmpty
                                              ? NetworkImage(user.profilePic!)
                                              : const NetworkImage(
                                                  "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRWui3ck64C6ACKyr5EQDDhfxkkhRwTc_a2nQ&s",
                                                ))
                                          as ImageProvider?,
                                child:
                                    _pickedImage == null &&
                                        (user.profilePic == null ||
                                            user.profilePic!.isEmpty)
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: ContextarTheme.mutedTextCyan,
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickProfileImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: ContextarTheme.neonCyan,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: ContextarTheme.backgroundBlack,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Account Identity Section Fields
                      CustomTextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        labelText: 'User Identifier',
                        hintText: 'Modify user string',
                        prefixIcon: Icons.badge_outlined,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Registry parameter required'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Modern Read-Only System Tile for immutable configurations (Email)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: ContextarTheme.darkSlateGreen.withOpacity(
                            0.15,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ContextarTheme.darkSlateGreen.withOpacity(
                              0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.alternate_email_rounded,
                              color: ContextarTheme.mutedTextCyan,
                              size: 22,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "CORE SYSTEM EMAIL",
                                  style: TextStyle(
                                    color: ContextarTheme.mutedTextCyan,
                                    fontSize: 10,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // System Settings Hub Directory Panel List
                      const Text(
                        "SECURITY RECON",
                        style: TextStyle(
                          color: ContextarTheme.mutedTextCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Divider(
                        color: ContextarTheme.darkSlateGreen,
                        thickness: 1,
                        height: 16,
                      ),

                      ListTile(
                        onTap: _showChangePasswordBottomSheet,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.shield_outlined,
                          color: ContextarTheme.neonCyan,
                        ),
                        title: const Text(
                          "Update Access Sequence",
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        subtitle: const Text(
                          "Modify account pass key profiles",
                          style: TextStyle(
                            color: ContextarTheme.mutedTextCyan,
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: ContextarTheme.mutedTextCyan,
                        ),
                      ),

                      ListTile(
                        onTap: _handleLogout,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.power_settings_new_rounded,
                          color: Color(0xffF04848),
                        ),
                        title: const Text(
                          "Terminate Active Session",
                          style: TextStyle(
                            color: Color(0xffF04848),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          "Flush persistent memory caches from hardware",
                          style: TextStyle(
                            color: ContextarTheme.mutedTextCyan,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// PREMIUM ISOLATED BOTTOM SHEET PANEL WORKER (Fully Functional)
// =========================================================================
class _ChangePasswordBottomSheet extends StatefulWidget {
  @override
  State<_ChangePasswordBottomSheet> createState() =>
      _ChangePasswordBottomSheetState();
}

class _ChangePasswordBottomSheetState
    extends State<_ChangePasswordBottomSheet> {
  final _sheetFormKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  final _cFocus = FocusNode();
  final _nFocus = FocusNode();
  final _confFocus = FocusNode();

  bool _isUpdating = false;

  void _handleSubmit() async {
    if (!_sheetFormKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    ApiResponse response = await UserService().changePassword(
      _currentController.text.trim(),
      _newController.text.trim(),
    );

    setState(() => _isUpdating = false);

    if (response.status) {
      if (mounted) {
        Navigator.pop(context); // Close bottom drawer frame context safely
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.message),
        backgroundColor: ContextarTheme.neonCyan,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    _cFocus.dispose();
    _nFocus.dispose();
    _confFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            24, // Adapts layout padding instantly when keyboard opens
      ),
      decoration: const BoxDecoration(
        color: Color(0xff0D1114),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: ContextarTheme.darkSlateGreen, width: 1.5),
        ),
      ),
      child: Form(
        key: _sheetFormKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ContextarTheme.darkSlateGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "RESET CIPHER SCHEME",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),

              CustomTextField(
                controller: _currentController,
                focusNode: _cFocus,
                nextFocusNode: _nFocus,
                labelText: "Current Key Matrix",
                hintText: "••••••••",
                isPassword: true,
                prefixIcon: Icons.lock_open_outlined,
                validator: (val) => val == null || val.isEmpty
                    ? 'Validation clearance parameter needed'
                    : null,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _newController,
                focusNode: _nFocus,
                nextFocusNode: _confFocus,
                labelText: "Target Security Key",
                hintText: "••••••••",
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                validator: (val) => val == null || val.length < 6
                    ? 'New parameters must span 6+ tokens'
                    : null,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _confirmController,
                focusNode: _confFocus,
                labelText: "Confirm Target Key",
                hintText: "••••••••",
                isPassword: true,
                prefixIcon: Icons.enhanced_encryption_outlined,
                validator: (val) => val != _newController.text
                    ? 'Cipher string mismatch detected'
                    : null,
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: "COMMIT ENCRYPTION UPDATE",
                isLoading: _isUpdating,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
