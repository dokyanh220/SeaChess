import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/presentation/providers/auth_providers.dart';
import 'package:client/presentation/providers/user_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedAvatar;
  bool _isSaving = false;

  // Danh sách avatar có sẵn trong assets/avatar/
  // Khi thêm avatar mới, chỉ cần thêm file avt_03.png, avt_04.png... vào thư mục
  // rồi thêm tên vào list này
  final List<String> _avatars = [
    'avt_01.png',
    'avt_02.png',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProfile = ref.read(userProfileProvider).value;
      if (userProfile != null) {
        setState(() {
          _nameController.text = userProfile.displayName;
          // Nếu avatarUrl hiện tại trùng với một preset → highlight nó
          if (userProfile.avatarUrl != null) {
            final currentAvatar = userProfile.avatarUrl!;
            // avatarUrl từ server sẽ lưu dạng "avt_01.png"
            if (_avatars.contains(currentAvatar)) {
              _selectedAvatar = currentAvatar;
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final userRepo = ref.read(userRepositoryProvider);

    setState(() => _isSaving = true);

    try {
      final result = await userRepo.updateProfile(
        displayName: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
        avatarUrl: _selectedAvatar, // Gửi tên file: "avt_01.png"
      );

      if (result != null && mounted) {
        // Refresh lại userProfileProvider để toàn bộ app cập nhật
        ref.invalidate(userProfileProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật hồ sơ thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thất bại. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar hiện tại ──────────────────────────────
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: colorScheme.primaryContainer,
                    backgroundImage: _selectedAvatar != null
                        ? AssetImage('assets/avatar/$_selectedAvatar')
                        : null,
                    child: _selectedAvatar == null
                        ? Icon(Icons.person, size: 50, color: colorScheme.primary)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.surface, width: 3),
                      ),
                      child: Icon(Icons.edit, color: colorScheme.onPrimary, size: 20),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Tên hiển thị ─────────────────────────────────
            Text(
              'Tên hiển thị',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              enabled: !_isSaving,
              decoration: InputDecoration(
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Nhập tên hiển thị của bạn',
                prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
              ),
            ),
            const SizedBox(height: 32),

            // ── Chọn ảnh đại diện ───────────────────────────
            Text(
              'Chọn ảnh đại diện',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _avatars.length,
              itemBuilder: (context, index) {
                final avatar = _avatars[index];
                final isSelected = _selectedAvatar == avatar;
                return GestureDetector(
                  onTap: _isSaving
                      ? null
                      : () {
                          setState(() {
                            _selectedAvatar = avatar;
                          });
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withOpacity(0.2)
                          : colorScheme.surfaceContainerHigh.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? colorScheme.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset('assets/avatar/$avatar'),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 48),

            // ── Nút Lưu ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Lưu thay đổi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
