import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../shared/services/firestore_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/location_utils.dart';
import '../../../shared/widgets/count_badge.dart';
import '../../../shared/widgets/shramdaan_network_image.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../events/screens/create_event_screen.dart';
import '../../leaderboard/screens/leaderboard_screen.dart';
import '../../notifications/services/notification_service.dart';
import '../../profile/screens/profile_screen.dart';
import 'home_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();

  static const List<Widget> _pages = <Widget>[
    HomePage(),
    ChatListScreen(),
    SizedBox.shrink(),
    LeaderboardScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocationUtils.prewarmCurrentPosition();
      NotificationService.instance.initializeForCurrentUser();
    });
  }

  Future<void> _onItemTapped(int index) async {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateEventScreen()),
      );
      return;
    }

    if (index == 1) {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        await _firestoreService.markMatchingNotificationsRead(
          currentUserId,
          types: const ['chat_message'],
        );
      }
      await NotificationService.instance.clearDisplayedNotifications(
        types: const ['chat_message'],
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final accountPhotoUrl = currentUser?.photoURL?.trim();

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: currentUserId == null
          ? _buildNavBar(context, 0, null)
          : StreamBuilder<int>(
              stream: _firestoreService.getUnreadNotificationCountByTypes(
                currentUserId,
                const ['chat_message'],
              ),
              builder: (context, snapshot) {
                final chatBadgeCount = snapshot.data ?? 0;
                return _buildNavBar(
                  context,
                  chatBadgeCount,
                  accountPhotoUrl != null && accountPhotoUrl.isNotEmpty
                      ? accountPhotoUrl
                      : null,
                );
              },
            ),
    );
  }

  Widget _buildNavBar(
    BuildContext context,
    int chatBadgeCount,
    String? accountPhotoUrl,
  ) {
    const items = <_NavItemData>[
      _NavItemData(
        icon: FontAwesomeIcons.houseChimney,
        activeIcon: FontAwesomeIcons.houseChimney,
        label: 'Home',
      ),
      _NavItemData(
        icon: FontAwesomeIcons.paperPlane,
        activeIcon: FontAwesomeIcons.paperPlane,
        label: 'Chats',
      ),
      _NavItemData(
        icon: FontAwesomeIcons.plus,
        activeIcon: FontAwesomeIcons.plus,
        label: 'Post',
      ),
      _NavItemData(
        icon: FontAwesomeIcons.trophy,
        activeIcon: FontAwesomeIcons.trophy,
        label: 'Leaders',
      ),
      _NavItemData(
        icon: FontAwesomeIcons.circleUser,
        activeIcon: FontAwesomeIcons.circleUser,
        label: 'Account',
      ),
    ];

    return SafeArea(
      minimum: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              offset: const Offset(0, 4),
              color: Colors.black.withOpacity(.04),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = _selectedIndex == index;
            final color = selected
                ? AppColors.primary
                : AppColors.textSecondary;

            return Expanded(
              child: _HomeNavButton(
                label: item.label,
                icon: selected ? item.activeIcon : item.icon,
                selected: selected,
                onTap: () => _onItemTapped(index),
                badgeCount: index == 1 ? chatBadgeCount : 0,
                color: color,
                profilePhotoUrl: index == 4 ? accountPhotoUrl : null,
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItemData {
  final FaIconData icon;
  final FaIconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _HomeNavButton extends StatelessWidget {
  final String label;
  final FaIconData icon;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;
  final Color color;
  final String? profilePhotoUrl;

  const _HomeNavButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.badgeCount,
    required this.color,
    this.profilePhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final showProfilePhoto =
        profilePhotoUrl != null && profilePhotoUrl!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  if (showProfilePhoto)
                    Container(
                      width: selected ? 28 : 26,
                      height: selected ? 28 : 26,
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                          width: selected ? 1.6 : 1.2,
                        ),
                      ),
                      child: ClipOval(
                        child: IgnorePointer(
                          child: ShramdaanNetworkImage(
                            imageUrl: profilePhotoUrl!,
                            width: selected ? 25 : 23,
                            height: selected ? 25 : 23,
                            fit: BoxFit.cover,
                            errorWidget: FaIcon(
                              FontAwesomeIcons.circleUser,
                              color: color,
                              size: selected ? 22 : 21,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    FaIcon(icon, color: color, size: selected ? 22 : 21),
                  if (badgeCount > 0)
                    Positioned(
                      right: -12,
                      top: -6,
                      child: CountBadge(count: badgeCount, minSize: 16),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12,
                      height: 1,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
