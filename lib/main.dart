import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_theme.dart';
import 'core/app_colors.dart';
import 'database/local_database.dart';
import 'models/app_user.dart';
import 'widgets/app_header.dart';
import 'widgets/side_menu.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/items_screen.dart';
import 'screens/invoice_screen.dart';
import 'screens/people_screen.dart';
import 'screens/capital_screen.dart';
import 'screens/bank_accounts_audit_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/telegram_settings_screen.dart';
import 'screens/sync_center_screen.dart';
import 'screens/debts_screen.dart';
import 'screens/financial_transactions_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDatabase.instance.init();
  runApp(const AldoodMarketApp());
}

class AldoodMarketApp extends StatefulWidget {
  const AldoodMarketApp({super.key});

  @override
  State<AldoodMarketApp> createState() => _AldoodMarketAppState();
}

class _AldoodMarketAppState extends State<AldoodMarketApp> {
  AppUser? currentUser;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الدود ماركت',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkArabicTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: currentUser == null
          ? LoginScreen(onLoggedIn: (user) => setState(() => currentUser = user))
          : Directionality(
              textDirection: TextDirection.rtl,
              child: MainShell(
                user: currentUser!,
                onLogout: () => setState(() => currentUser = null),
              ),
            ),
    );
  }
}

class MainShell extends StatefulWidget {
  final AppUser user;
  final VoidCallback onLogout;

  const MainShell({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String selected = 'dashboard';

  Widget _screen() {
    switch (selected) {
      case 'items':
        return const ItemsScreen();
      case 'sales':
        return const InvoiceScreen(type: InvoiceType.sales);
      case 'purchases':
        return const InvoiceScreen(type: InvoiceType.purchases);
      case 'customers':
        return const PeopleScreen(kind: PeopleKind.customers);
      case 'suppliers':
        return const PeopleScreen(kind: PeopleKind.suppliers);
      case 'capital':
        return const CapitalScreen();
      case 'debts':
        return const DebtsScreen();
      case 'financial':
        return const FinancialTransactionsScreen();
      case 'bank_audit':
        return const BankAccountsAuditScreen();
      case 'notes':
        return const NotesScreen();
      case 'sync_center':
        return const SyncCenterScreen();
      case 'telegram':
        return const TelegramSettingsScreen();
      default:
        return const DashboardScreen();
    }
  }

  String _title() {
    final item = appMenuItems.firstWhere((e) => e.id == selected, orElse: () => appMenuItems.first);
    return item.title;
  }

  void _select(String id) {
    if (scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    setState(() => selected = id);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 950;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppColors.bgApp,
      endDrawer: wide
          ? null
          : AppEndDrawer(
              selected: selected,
              onSelect: _select,
              onLogout: widget.onLogout,
              user: widget.user,
            ),
      body: Row(
        textDirection: TextDirection.rtl,
        children: [
          if (wide)
            SideMenuPanel(
              selected: selected,
              onSelect: _select,
              onLogout: widget.onLogout,
              permanent: true,
              user: widget.user,
            ),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  AppHeader(
                    title: _title(),
                    user: widget.user,
                    showMenuButton: !wide,
                    onMenuPressed: () => scaffoldKey.currentState?.openEndDrawer(),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _screen(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
