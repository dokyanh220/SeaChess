import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/presentation/providers/user_providers.dart';
import 'package:client/presentation/providers/friendship_providers.dart';
import 'package:client/presentation/providers/notification_providers.dart';
import 'package:client/domain/models/UserProfileResponse.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notificationState = ref.watch(notificationStateProvider);
    final pendingCount = notificationState.pendingRequestsCount;

    ref.listen(notificationStateProvider, (previous, next) {
      if (previous?.pendingRequestsCount != next.pendingRequestsCount) {
        _fetchData();
      }
    });

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
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
            tabs: [
              const Tab(text: 'Bạn bè'),
              const Tab(text: 'Tìm kiếm'),
              Tab(
                child: Badge(
                  isLabelVisible: pendingCount > 0,
                  label: Text(pendingCount.toString()),
                  backgroundColor: Colors.redAccent,
                  child: const Text('Lời mời'),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFriendsOnlyTab(colorScheme),
            _buildSearchTab(colorScheme),
            _buildRequestsTab(colorScheme),
          ],
        ),
      ),
    );
  }

  String _searchQuery = '';
  int _searchMode = 0; // 0: Tên, 1: ID
  final TextEditingController _searchController = TextEditingController();
  
  bool _isSearching = false;
  bool _isLoading = false;
  List<UserProfile> _searchResults = [];

  List<UserProfile> _friends = [];
  List<UserProfile> _pendingRequests = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    // Fetch dữ liệu khi mở màn hình
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoadingData = true);
    final repo = ref.read(friendshipRepositoryProvider);
    
    final friends = await repo.getFriends();
    final requests = await repo.getPendingRequests();
    
    if (mounted) {
      setState(() {
        _friends = friends;
        _pendingRequests = requests;
        _isLoadingData = false;
      });
      // Cập nhật lại số đếm ở provider
      ref.read(notificationStateProvider.notifier).fetchPendingCount();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _performSearch() async {
    if (_searchQuery.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _isSearching = true;
    });
    
    final repo = ref.read(userRepositoryProvider);
    final results = await repo.searchUsers(_searchQuery.trim());
    
    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  Widget _buildFriendsOnlyTab(ColorScheme colorScheme) {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_friends.isEmpty) {
      return const Center(child: Text("Bạn chưa có người bạn nào"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friend = _friends[index];
        return _buildFriendItem(friend, colorScheme);
      },
    );
  }

  Widget _buildSearchTab(ColorScheme colorScheme) {
    return Column(
      children: [
        // ========== SEARCH BAR ==========
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              suffixIcon: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.search, color: colorScheme.onPrimary, size: 20),
                        onPressed: _performSearch,
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
            onSubmitted: (_) => _performSearch(),
          ),
        ),
        
        // ========== SEARCH RESULTS ==========
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _isSearching
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return _buildSearchResultItem(user, colorScheme);
                    },
                  )
                : const Center(child: Text("Nhập ID hoặc tên để tìm kiếm")),
        ),
      ],
    );
  }

  Widget _buildSearchResultItem(UserProfile user, ColorScheme colorScheme) {
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
                  user.displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${user.userId} • Cấp ${user.level}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (user.friendshipStatus != 'Accepted')
            if (user.friendshipStatus == 'Pending')
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
                  foregroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: null, // Disabled
                child: const Text('Đã gửi'),
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final repo = ref.read(friendshipRepositoryProvider);
                  final success = await repo.sendFriendRequest(user.username);
                  if (mounted) {
                    if (success) {
                      setState(() {
                        final index = _searchResults.indexWhere((u) => u.id == user.id);
                        if (index != -1) {
                          _searchResults[index] = user.copyWith(friendshipStatus: 'Pending');
                        }
                      });
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'Đã gửi lời mời!' : 'Lỗi khi gửi lời mời')),
                    );
                  }
                },
                child: const Text('Kết bạn'),
              ),
        ],
      ),
    );
  }

  Widget _buildFriendItem(
    UserProfile friend,
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
                  friend.displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cấp độ ${friend.level}',
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
    UserProfile friend,
    ColorScheme colorScheme,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                friend.displayName,
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
                  Navigator.pop(sheetContext);
                  // TODO: Thêm logic đặt biệt danh
                },
              ),
              ListTile(
                leading: Icon(Icons.person_remove, color: colorScheme.error),
                title: Text(
                  'Xoá bạn bè',
                  style: TextStyle(color: colorScheme.error),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final repo = ref.read(friendshipRepositoryProvider);
                  final success = await repo.removeFriend(friend.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'Đã xoá bạn bè' : 'Lỗi khi xoá bạn')),
                    );
                    if (success) _fetchData();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab(ColorScheme colorScheme) {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingRequests.isEmpty) {
      return const Center(child: Text('Không có lời mời nào'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final req = _pendingRequests[index];
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
                          req.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cấp độ ${req.level} muốn kết bạn',
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
                      onPressed: () async {
                        final repo = ref.read(friendshipRepositoryProvider);
                        final success = await repo.declineFriendRequest(req.id);
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(success ? 'Đã từ chối lời mời' : 'Lỗi khi từ chối')),
                          );
                          if (success) _fetchData();
                        }
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
                      onPressed: () async {
                        final repo = ref.read(friendshipRepositoryProvider);
                        final success = await repo.acceptFriendRequest(req.id);
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(success ? 'Đã chấp nhận kết bạn' : 'Lỗi khi chấp nhận')),
                          );
                          if (success) _fetchData();
                        }
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
