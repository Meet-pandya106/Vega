import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/biometric_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../quick_punch/quick_punch_screen.dart';
import '../tradebook/tradebook_screen.dart';
import '../calendar/calendar_screen.dart';
import '../accounting/accounting_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authenticateUser();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      setState(() => _isAuthenticated = false);
    } else if (state == AppLifecycleState.resumed && !_isAuthenticated) {
      _authenticateUser();
    }
  }

  Future<void> _authenticateUser() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;

    final authenticated = await BiometricService.authenticate();
    setState(() {
      _isAuthenticated = authenticated;
      _isAuthenticating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.cardPurple.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(color: AppTheme.cardPurple.withOpacity(0.2), blurRadius: 24),
                  ],
                ),
                child: const Icon(Icons.fingerprint_rounded, size: 68, color: AppTheme.cardPurple),
              ),
              const SizedBox(height: 24),
              const Text(
                "Vega Locked",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                "Touch biometric sensor or enter device PIN",
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cardPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.lock_open_rounded, size: 18),
                label: const Text("Unlock Vega", style: TextStyle(fontWeight: FontWeight.w800)),
                onPressed: _authenticateUser,
              ),
            ],
          ),
        ),
      );
    }

    final screens = [
      DashboardScreen(onQuickPunchTap: () => setState(() => _currentIndex = 1)),
      QuickPunchScreen(onSaved: () => setState(() => _currentIndex = 0)),
      const TradebookScreen(),
      const CalendarScreen(),
      const AccountingScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      // FLOATING PILL DOCK (Matching Reference Mockup)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.dockBackground,
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: AppTheme.borderSubtle, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDockItem(0, "Home", Icons.home_rounded, Icons.home_outlined),
                _buildDockItem(1, "Punch", Icons.bolt_rounded, Icons.bolt_outlined),
                _buildDockItem(2, "Trades", Icons.menu_book_rounded, Icons.menu_book_outlined),
                _buildDockItem(3, "Calendar", Icons.calendar_month_rounded, Icons.calendar_month_outlined),
                _buildDockItem(4, "Taxes", Icons.account_balance_rounded, Icons.account_balance_outlined),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem(int index, String label, IconData activeIcon, IconData inactiveIcon) {
    final isSelected = _currentIndex == index;

    if (isSelected) {
      return GestureDetector(
        onTap: () => HapticFeedback.selectionClick(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.activePillWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.white24,
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(activeIcon, size: 18, color: AppTheme.activePillText),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.activePillText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return IconButton(
      icon: Icon(inactiveIcon, size: 22, color: AppTheme.textSecondary),
      onPressed: () {
        HapticFeedback.selectionClick();
        setState(() => _currentIndex = index);
      },
    );
  }
}
