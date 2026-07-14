import 'package:flutter/material.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurface,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Bạn bè',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          bottom: TabBar(
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            tabs: const [
              Tab(text: 'Danh sách'),
              Tab(text: 'Lời mời'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFriendsTab(colorScheme),
            _buildRequestsTab(colorScheme),
          ],
        ),
      ),
    );
  }

  String _searchQuery = '';
  int _searchMode = 0; // 0: Tên, 1: ID
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFriendsTab(ColorScheme colorScheme) {
    final demoFriends = [
      {'name': 'Nguyễn Văn A', 'level': 12, 'id': 'ID-1234', 'avatar': null},
      {'name': 'Trần B', 'level': 8, 'id': 'ID-5678', 'avatar': null},
      {'name': 'GosuChess', 'level': 34, 'id': 'ID-9999', 'avatar': null},
    ];

    return Column(
      children: [
        // ========== SEARCH BAR ==========
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: _searchMode == 0 ? 'Tìm theo tên...' : 'Tìm theo ID...',
              suffixIcon: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _searchMode,
                        icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
                        dropdownColor: colorScheme.surfaceContainerHigh,
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Tên')),
                          DropdownMenuItem(value: 1, child: Text('ID')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _searchMode = val;
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.search, color: colorScheme.onPrimary, size: 20),
                        onPressed: () {
                          // TODO: Thực hiện logic tìm kiếm API
                        },
                      ),
                    ),
                  ],
                ),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHigh.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        
        // ========== FRIENDS LIST ==========
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: demoFriends.length,
            itemBuilder: (context, index) {
              final friend = demoFriends[index];
              return _buildFriendItem(friend, colorScheme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFriendItem(
    Map<String, dynamic> friend,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.person, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend['name'].toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cấp độ ${friend['level']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
            onPressed: () {
              _showFriendOptionsBottomSheet(friend, colorScheme);
            },
          ),
        ],
      ),
    );
  }

  void _showFriendOptionsBottomSheet(
    Map<String, dynamic> friend,
    ColorScheme colorScheme,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                friend['name'].toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Icon(Icons.edit, color: colorScheme.primary),
                title: Text(
                  'Đặt biệt danh',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Thêm logic đặt biệt danh
                },
              ),
              ListTile(
                leading: Icon(Icons.person_remove, color: colorScheme.error),
                title: Text(
                  'Xoá bạn bè',
                  style: TextStyle(color: colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Thêm logic xoá bạn
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab(ColorScheme colorScheme) {
    final demoRequests = [
      {'name': 'Người Chơi Mới', 'level': 2, 'avatar': null},
      {'name': 'Cao Thủ Ẩn Danh', 'level': 50, 'avatar': null},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: demoRequests.length,
      itemBuilder: (context, index) {
        final req = demoRequests[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.secondaryContainer,
                    child: Icon(Icons.person, color: colorScheme.secondary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req['name'].toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cấp độ ${req['level']} muốn kết bạn',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: colorScheme.error.withOpacity(0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // TODO: Từ chối
                      },
                      child: Text(
                        'Từ chối',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // TODO: Chấp nhận
                      },
                      child: const Text('Chấp nhận'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
