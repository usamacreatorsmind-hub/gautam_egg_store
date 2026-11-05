import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sure_wholesaler/core/routing/app_router.dart';
import 'package:sure_wholesaler/core/theme/theme_extension.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/core/providers/policy_provider.dart';
import 'package:sure_wholesaler/models/UserModel.dart';
import 'package:sure_wholesaler/core/routing/app_routes.dart';
import 'package:sure_wholesaler/notifiers/favorites_notifier.dart';
import 'package:sure_wholesaler/notifiers/user_notifier.dart';
import 'package:sure_wholesaler/screens/navigation/NavigationButton.dart';
import 'package:sure_wholesaler/widgets/image_builder.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: _ErrorState(message: 'User not logged in'),
      );
    }

    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (_, innerScrolled) => [
          userAsync.maybeWhen(
            data: (user) {
              if (user == null) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }

              return SliverAppBar(
                pinned: true,
                stretch: true,
                expandedHeight: 310.h,
                elevation: innerScrolled ? 1 : 0,
                backgroundColor: scheme.surface,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  centerTitle: true,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primary.withOpacity(0.08),
                          scheme.primaryContainer.withOpacity(0.18),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(34.r),
                        bottomRight: Radius.circular(34.r),
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 10.h),

                            /// Profile Avatar
                            Container(
                              padding: EdgeInsets.all(5.w),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: scheme.primary.withOpacity(0.15),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 42.r,
                                backgroundColor: scheme.primary.withOpacity(0.12),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 42.sp,
                                  color: scheme.primary,
                                ),
                              ),
                            ),

                            SizedBox(height: 18.h),

                            /// Username
                            Text(
                              user.userName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),

                            SizedBox(height: 6.h),

                            /// Email
                            Text(
                              user.email ?? "",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),

                            SizedBox(height: 24.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
        ],
        body: userAsync.when(
          loading: () => const _LoadingState(),
          error: (e, _) => Padding(
            padding: EdgeInsets.all(40.w),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.orange, size: 48),
                  SizedBox(height: 12.h),
                  const Text("Syncing profile...", style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 8.h),
                  TextButton.icon(
                    onPressed: () => ref.read(userProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retry"),
                  ),
                ],
              ),
            ),
          ),
          data: (user) => user == null
              ? _ErrorState(
                  message: 'User profile not found in database',
                  actionLabel: 'Setup Profile',
                  onAction: () {
                    final mobile = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
                    context.push(AppRoutes.userSetup, extra: mobile);
                  },
                )
              : _ProfileContent(user: user),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 22.sp,
          color: scheme.primary,
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// ---------------- CONTENT ----------------

class _ProfileContent extends StatelessWidget {
  final UserModel user;

  const _ProfileContent({required this.user});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode == true) debugPrint(user.toString());
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.r),
          topRight: Radius.circular(30.r),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(12.w, 16.h, 12.w, 30.h),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  const QuickActions(),
                  SizedBox(height: 10.h),
                  const _MenuOptions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------- HEADER ----------------

/// ---------------- MENU ----------------

class MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const MenuSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 18.h),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(26.r),
          border: Border.all(
            color: scheme.outlineVariant.withOpacity(0.16),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 10),
              color: Colors.black.withOpacity(0.025),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 10.h),
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuOptions extends ConsumerWidget {
  const _MenuOptions();

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _launchPrivacy(WidgetRef ref) async {
    final policy = await ref.read(policyProvider.future);
    _launchUrl(policy.privacyUrl);
  }

  Future<void> _launchTerms(WidgetRef ref) async {
    final policy = await ref.read(policyProvider.future);
    _launchUrl(policy.termsUrl);
  }

  Future<void> _launchDisclaimer(WidgetRef ref) async {
    final policy = await ref.read(policyProvider.future);
    _launchUrl(policy.disclaimerUrl);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        MenuSection(
          title: "Account",
          children: [
            _MenuTile(
              icon: Icons.edit_outlined,
              title: 'Update Profile',
              subtitle: 'Edit your name, email and photo',
              onTap: () => context.push(AppRoutes.editProfile),
            ),
            _MenuTile(
              icon: Icons.add_box_outlined,
              title: 'Manage Address',
              subtitle: 'Manage your delivery addresses',
              onTap: () => context.push(AppRoutes.address),
            ),
          ],
        ),
        MenuSection(
          title: "Shopping",
          children: [
            _MenuTile(
              icon: Icons.favorite,
              title: 'Favourites Products',
              subtitle: 'Your saved items',
              onTap: () => context.push(AppRoutes.favoriteProducts),
            ),
// _MenuTile(
// icon: Icons.autorenew,
// title: 'My Subscriptions',
// subtitle: 'Manage your recurring orders',
// onTap: () => context.push(AppRoutes.mySubscriptions),
// ),
          ],
        ),
        MenuSection(
          title: "Support & Legal",
          children: [
            _MenuTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'Learn about our privacy practices',
              onTap: () => _launchPrivacy(ref),
            ),
            _MenuTile(
              icon: Icons.description_outlined,
              title: 'Terms and Conditions',
              subtitle: 'Read our terms and conditions',
              onTap: () => _launchTerms(ref),
            ),
            _MenuTile(
              icon: Icons.gavel_outlined,
              title: 'Disclaimer',
              subtitle: 'Legal disclaimer and notes',
              onTap: () => _launchDisclaimer(ref),
            ),
            _MenuTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help and contact support',
              onTap: () => context.push(AppRoutes.helpSupport),
            ),
          ],
        ),
        MenuSection(
          title: "Account Actions",
          children: [
            _MenuTile(
              onTap: () => _showLogoutDialog(context),
              icon: Icons.logout,
              title: 'Log Out',
              subtitle: 'Sign out of your account',
            ),
          ],
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: 18.w,
        vertical: 4.h,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.r),
      ),
      leading: Container(
        height: 48.w,
        width: 48.w,
        decoration: BoxDecoration(
          color: scheme.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(
          icon,
          color: scheme.primary,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 2.h),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.sp,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16.sp,
        color: scheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

/// ---------------- STATES ----------------

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.staggeredDotsWave(
        color: Theme.of(context).colorScheme.primary,
        size: 60,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onAction;
  final String? actionLabel;

  const _ErrorState({
    required this.message,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: theme.colorScheme.error),
            SizedBox(height: 16.h),
            Text(message, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
            if (onAction != null && actionLabel != null) ...[
              SizedBox(height: 20.h),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandSeed,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                ),
              ),
            ],
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}

/// ---------------- LOGOUT ----------------

void _showLogoutDialog(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;

  showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72.w,
              width: 72.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.error.withOpacity(0.10),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: scheme.error,
                size: 34.sp,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              "Log Out",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Are you sure you want to sign out of your account?",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            SizedBox(height: 28.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);

                      AppRouter.clearProfileCache();

                      try {
                        ProviderScope.containerOf(context, listen: false).read(navIndexProvider.notifier).state = 0;
                      } catch (_) {}

                      await FirebaseAuth.instance.signOut();
                      await Future.delayed(const Duration(milliseconds: 100));

                      if (context.mounted) {
                        context.go(AppRoutes.login);
                      }
                    },
                    child: const Text("Log Out"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class QuickActions extends ConsumerWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 14.h,
        horizontal: 10.w,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(26.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.18),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.03),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildItem(
            context,
            Icons.delivery_dining_rounded,
            "Orders",
            AppRoutes.orders,
          ),
// _buildItem(
// context,
// Icons.account_balance_wallet_rounded,
// "Wallet",
// AppRoutes.walletHomeScreen,
// ),
          _buildItem(
            context,
            Icons.location_on_rounded,
            "Address",
            AppRoutes.address,
          ),
          _buildItem(
            context,
            Icons.support_agent_rounded,
            "Help",
            AppRoutes.helpSupport,
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    final colors = context.colors;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: () => context.push(route),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            children: [
              Container(
                height: 58.w,
                width: 58.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withOpacity(0.12),
                      colors.primary.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Icon(
                  icon,
                  size: 28.sp,
                  color: colors.primary,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
