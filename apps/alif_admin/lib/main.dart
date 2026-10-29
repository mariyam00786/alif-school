import "package:flutter/material.dart";
import "package:alif_design_system/alif_design_system.dart";

import "screens/batch_management_page.dart";
import "screens/class_management_page.dart";
import "screens/configuration_page.dart";
import "screens/daily_marking_page.dart";
import "screens/badges_page.dart";
import "screens/notifications_page.dart";
import "screens/reports_page.dart";
import "screens/remarks_page.dart";
import "screens/student_management_page.dart";
import "screens/teacher_management_page.dart";
import "services/auth_service.dart";
import "services/device_token_service.dart";
import "services/firebase_options.dart";
import "services/fcm_service.dart";
import "package:firebase_core/firebase_core.dart";

class _AdminDestination {
  const _AdminDestination({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.page,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Widget page;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase for FCM
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[Firebase] Initialized successfully');
    
    // Initialize FCM service
    try {
      await FcmService.initialize();
    } catch (e) {
      debugPrint('FCM initialization error (continuing anyway): $e');
    }
  } catch (e) {
    debugPrint('[Firebase] Initialization error (continuing anyway): $e');
  }
  
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Alif Admin",
      debugShowCheckedModeBanner: false,
      theme: AlifTheme.light(),
      home: const AdminAuthGate(),
    );
  }
}

class AdminAuthGate extends StatefulWidget {
  const AdminAuthGate({super.key});

  @override
  State<AdminAuthGate> createState() => _AdminAuthGateState();
}

class _AdminAuthGateState extends State<AdminAuthGate> {
  AuthSession? _session;
  bool _tokenRefreshListenerAttached = false;

  Future<void> _registerFcmForSession(AuthSession session) async {
    final token = FcmService.getToken() ?? await FcmService.refreshToken();
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      await DeviceTokenService.registerToken(
        accessToken: session.accessToken,
        token: token,
        role: session.user.role,
      );
    } catch (error) {
      debugPrint('FCM token registration failed: $error');
    }

    if (_tokenRefreshListenerAttached) {
      return;
    }

    FcmService.onTokenRefresh((newToken) {
      DeviceTokenService.registerToken(
        accessToken: session.accessToken,
        token: newToken,
        role: session.user.role,
      ).catchError((error) {
        debugPrint('FCM token refresh registration failed: $error');
      });
    });
    _tokenRefreshListenerAttached = true;
  }

  void _onLoggedIn(AuthSession session) {
    setState(() => _session = session);
    _registerFcmForSession(session);
  }

  void _logout() {
    final session = _session;
    final token = FcmService.getToken();
    if (session != null && token != null && token.isNotEmpty) {
      DeviceTokenService.unregisterToken(
        accessToken: session.accessToken,
        token: token,
      ).catchError((error) {
        debugPrint('FCM token unregister failed: $error');
      });
    }

    AuthService.clearToken();
    setState(() => _session = null);
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) {
      return LoginPage(onLoggedIn: _onLoggedIn);
    }

    if (session.user.role != 'admin') {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AlifSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block_rounded, size: 48, color: AlifColors.danger),
                const SizedBox(height: AlifSpacing.md),
                Text(
                  'Only admin role can access this app.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AlifSpacing.md),
                AlifButton(label: 'Logout', expand: false, onPressed: _logout),
              ],
            ),
          ),
        ),
      );
    }

    return AdminHomePage(session: session, onLogout: _logout);
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLoggedIn});

  final ValueChanged<AuthSession> onLoggedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController(text: '9999999999');
  final _otpController = TextEditingController(text: AuthService.devOtp);
  bool _otpSent = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await AuthService.sendOtp(phone: _phoneController.text.trim());
      if (!mounted) {
        return;
      }
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP sent. Dev OTP: ${AuthService.devOtp}')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = await AuthService.verifyOtp(
        phone: _phoneController.text.trim(),
        otp: _otpController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      widget.onLoggedIn(session);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlifColors.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AlifSpacing.lg),
            child: AlifCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin Login', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AlifSpacing.sm),
                  Text(
                    'Use admin phone 9999999999 for today\'s experiment.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AlifColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AlifSpacing.lg),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '9999999999',
                    ),
                  ),
                  const SizedBox(height: AlifSpacing.md),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'OTP',
                      hintText: '123456',
                    ),
                  ),
                  const SizedBox(height: AlifSpacing.md),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AlifSpacing.md),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AlifColors.danger),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: _isLoading ? null : _sendOtp,
                          child: const Text('Send OTP'),
                        ),
                      ),
                      const SizedBox(width: AlifSpacing.md),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isLoading || !_otpSent ? null : _verifyOtp,
                          child: const Text('Login'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({
    super.key,
    required this.session,
    required this.onLogout,
  });

  final AuthSession session;
  final VoidCallback onLogout;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  List<_AdminDestination> get _destinations => const [
        _AdminDestination(
          label: "Students",
          subtitle: "Admissions, profiles, and activity tracking",
          icon: Icons.people_alt_rounded,
          page: StudentManagementPage(),
        ),
        _AdminDestination(
          label: "Teachers",
          subtitle: "Faculty setup, batch mapping, and ownership",
          icon: Icons.school_rounded,
          page: TeacherManagementPage(),
        ),
        _AdminDestination(
          label: "Batches",
          subtitle: "Class groups, schedules, and status control",
          icon: Icons.groups_rounded,
          page: BatchManagementPage(),
        ),
        _AdminDestination(
          label: "Classes",
          subtitle: "Level setup and batch-linked class records",
          icon: Icons.class_rounded,
          page: ClassManagementPage(),
        ),
        _AdminDestination(
          label: "Daily Marking",
          subtitle: "Mark activities for each student by day",
          icon: Icons.fact_check_rounded,
          page: DailyMarkingPage(),
        ),
        _AdminDestination(
          label: "Reports",
          subtitle: "Daily, weekly, and monthly summary reports",
          icon: Icons.summarize_rounded,
          page: ReportsPage(),
        ),
        _AdminDestination(
          label: "Badges",
          subtitle: "Achievement badges and bonus points",
          icon: Icons.workspace_premium_rounded,
          page: BadgesPage(),
        ),
        _AdminDestination(
          label: "Notifications",
          subtitle: "Create and schedule broadcast messages",
          icon: Icons.notifications_active_rounded,
          page: NotificationsPage(),
        ),
        _AdminDestination(
          label: "Remarks",
          subtitle: "Teacher feedback and student remarks",
          icon: Icons.rate_review_rounded,
          page: RemarksPage(),
        ),
        _AdminDestination(
          label: "Configuration",
          subtitle: "Categories, activities, and rating settings",
          icon: Icons.tune_rounded,
          page: ConfigurationPage(),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations;
    final active = destinations[_selectedIndex];
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 960;
    final isMobile = width < 600;

    EdgeInsets bodyPadding;
    if (isDesktop) {
      bodyPadding = const EdgeInsets.all(AlifSpacing.lg);
    } else if (isMobile) {
      bodyPadding = EdgeInsets.zero;
    } else {
      bodyPadding = const EdgeInsets.all(AlifSpacing.sm);
    }

    return Scaffold(
      backgroundColor: AlifColors.bg,
      drawer: !isDesktop
          ? _MobileNavDrawer(
              destinations: destinations,
              selectedIndex: _selectedIndex,
              onSelected: (index) {
                setState(() => _selectedIndex = index);
                Navigator.of(context).pop();
              },
            )
          : null,
      body: Stack(
        children: [
          const _AtmosphereBackground(),
          SafeArea(
            child: Padding(
              padding: bodyPadding,
              child: isDesktop
                  ? Row(
                      children: [
                        _DesktopSidebar(
                          destinations: destinations,
                          selectedIndex: _selectedIndex,
                          onSelected: (index) {
                            setState(() => _selectedIndex = index);
                          },
                        ),
                        const SizedBox(width: AlifSpacing.lg),
                        Expanded(
                          child: _MainContentFrame(
                            destination: active,
                            session: widget.session,
                            onLogout: widget.onLogout,
                            child: active.page,
                          ),
                        ),
                      ],
                    )
                  : _MainContentFrame(
                      destination: active,
                      session: widget.session,
                      onLogout: widget.onLogout,
                      child: active.page,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileNavDrawer extends StatelessWidget {
  const _MobileNavDrawer({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_AdminDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AlifSpacing.lg,
                AlifSpacing.lg,
                AlifSpacing.lg,
                AlifSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ALIF Admin',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AlifSpacing.xs),
                  Text(
                    'School operations cockpit',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AlifColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  final item = destinations[index];
                  final selected = index == selectedIndex;
                  return ListTile(
                    leading: Icon(
                      item.icon,
                      color: selected ? AlifColors.primary : AlifColors.textSecondary,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                        color: selected ? AlifColors.primary : null,
                      ),
                    ),
                    selected: selected,
                    selectedTileColor: AlifColors.primary.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () => onSelected(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtmosphereBackground extends StatelessWidget {
  const _AtmosphereBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AlifColors.bg,
            AlifColors.primaryContainer.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(-1.2, -1.0),
            child: _GlowCircle(
              size: 220,
              color: AlifColors.secondaryContainer.withValues(alpha: 0.7),
            ),
          ),
          Align(
            alignment: const Alignment(1.1, -0.8),
            child: _GlowCircle(
              size: 260,
              color: AlifColors.primaryContainer.withValues(alpha: 0.85),
            ),
          ),
          Align(
            alignment: const Alignment(0.9, 1.0),
            child: _GlowCircle(
              size: 180,
              color: AlifColors.secondary.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_AdminDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AlifColors.border),
          boxShadow: const [
            BoxShadow(
              blurRadius: 28,
              offset: Offset(0, 12),
              color: Color(0x1F000000),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AlifSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ALIF Admin",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AlifSpacing.xs),
              Text(
                "School operations cockpit",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AlifColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AlifSpacing.xl),
              Expanded(
                child: ListView.separated(
                  itemCount: destinations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AlifSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = destinations[index];
                    final selected = index == selectedIndex;
                    return Material(
                      color: selected
                          ? AlifColors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => onSelected(index),
                        child: Padding(
                          padding: const EdgeInsets.all(AlifSpacing.md),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                color: selected
                                    ? AlifColors.primary
                                    : AlifColors.textSecondary,
                              ),
                              const SizedBox(width: AlifSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AlifColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainContentFrame extends StatelessWidget {
  const _MainContentFrame({
    required this.destination,
    required this.child,
    required this.session,
    required this.onLogout,
  });

  final _AdminDestination destination;
  final Widget child;
  final AuthSession session;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final radius = isMobile ? BorderRadius.zero : BorderRadius.circular(24);

    return ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          border: isMobile ? null : Border.all(color: AlifColors.border),
          borderRadius: radius,
          boxShadow: isMobile
              ? null
              : const [
                  BoxShadow(
                    blurRadius: 30,
                    offset: Offset(0, 12),
                    color: Color(0x22000000),
                  ),
                ],
        ),
        child: Column(
          children: [
            _HeroBar(destination: destination, session: session, onLogout: onLogout),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _HeroBar extends StatelessWidget {
  const _HeroBar({
    required this.destination,
    required this.session,
    required this.onLogout,
  });

  final _AdminDestination destination;
  final AuthSession session;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? AlifSpacing.md : AlifSpacing.xl,
        AlifSpacing.md,
        isMobile ? AlifSpacing.sm : AlifSpacing.xl,
        AlifSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AlifColors.primary.withValues(alpha: 0.95),
            AlifColors.accent.withValues(alpha: 0.92),
          ],
        ),
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              tooltip: 'Menu',
              onPressed: () => Scaffold.of(context).openDrawer(),
            )
          else
            Icon(destination.icon, color: Colors.white),
          const SizedBox(width: AlifSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (!isMobile) ...[
                  const SizedBox(height: 2),
                  Text(
                    destination.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Logged in as ${session.user.fullName} (${session.user.role})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              tooltip: 'Logout',
              onPressed: onLogout,
            )
          else
            FilledButton.tonalIcon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
