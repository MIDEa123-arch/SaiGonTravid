import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/models/user.dart';
import 'package:travel_app/services.dart/auth_service.dart';
import 'package:travel_app/services.dart/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService.currentUser;
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      print("Lỗi chọn ảnh: $e");
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = AuthService.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    
    final newName = _fullNameController.text.trim();
    final newEmail = _emailController.text.trim();
    String? uploadedAvatarUrl;

    // 1. Upload avatar if changed
    if (_selectedImage != null) {
      uploadedAvatarUrl = await _api.uploadAvatar(user.userId, _selectedImage!.path);
      if (uploadedAvatarUrl == null) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lỗi khi tải ảnh đại diện lên server.',
                style: GoogleFonts.beVietnamPro(),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    }

    // 2. Save profile updates (name, email)
    final errorDetail = await _api.updateUserProfile(user.userId, newName, newEmail);
    
    if (!mounted) return;
    
    if (errorDetail == null) {
      // Success! Update auth notifier
      final updatedUser = AppUser(
        userId: user.userId,
        fullName: newName,
        email: newEmail,
        avatarUrl: uploadedAvatarUrl ?? user.avatarUrl,
        googleId: user.googleId,
      );
      await AuthService.updateUser(updatedUser);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã cập nhật thông tin thành công.',
            style: GoogleFonts.beVietnamPro(),
          ),
          backgroundColor: AppColors.primaryEmerald,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorDetail,
            style: GoogleFonts.beVietnamPro(),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Vui lòng đăng nhập để xem hồ sơ')),
      );
    }

    // Resolve avatar image to display
    Widget avatarChild;
    if (_selectedImage != null) {
      avatarChild = ClipRRect(
        borderRadius: BorderRadius.circular(52),
        child: Image.file(
          File(_selectedImage!.path),
          fit: BoxFit.cover,
        ),
      );
    } else if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      // Build full url if it is relative
      String fullAvatarUrl = user.avatarUrl!;
      if (user.avatarUrl!.startsWith('/static')) {
        fullAvatarUrl = '${_api.getAvatarFullUrl(user.avatarUrl!)}';
      }
      avatarChild = ClipRRect(
        borderRadius: BorderRadius.circular(52),
        child: Image.network(
          fullAvatarUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Text(
              user.initials,
              style: GoogleFonts.beVietnamPro(
                color: Colors.black,
                fontSize: 36,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      );
    } else {
      avatarChild = Center(
        child: Text(
          user.initials,
          style: GoogleFonts.beVietnamPro(
            color: Colors.black,
            fontSize: 36,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thông tin tài khoản',
          style: GoogleFonts.beVietnamPro(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              
              // Avatar Section
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentMint,
                        ),
                        child: avatarChild,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E2E2E),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.accentMint,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Edit avatar action text
              GestureDetector(
                onTap: _pickAvatar,
                child: Text(
                  'Đổi ảnh đại diện',
                  style: GoogleFonts.beVietnamPro(
                    color: AppColors.accentMint,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              
              // Form Fields
              _buildLabel('Họ và tên'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _fullNameController,
                icon: Icons.edit_outlined,
                enabled: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              _buildLabel('Email'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                icon: Icons.edit_outlined,
                enabled: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(val.trim())) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 48),
              
              // Save Changes Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentMint,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          'Lưu thay đổi',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.beVietnamPro(
          color: Colors.white54,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      style: GoogleFonts.beVietnamPro(
        color: enabled ? Colors.white : Colors.white60,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        suffixIcon: Icon(
          icon,
          color: enabled ? AppColors.accentMint : Colors.white24,
          size: 18,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}
