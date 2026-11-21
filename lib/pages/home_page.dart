import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/wallet.dart';
import '../services/api_service.dart';
import '../utils/date_helper.dart';
import '../widgets/home/home_body.dart';
import 'chat_bot_page.dart';
import 'profile_page.dart';
import 'reports_page.dart';
import 'transactions_page.dart';
import 'utang_piutang_page.dart';

/// Halaman utama dengan 4 tab: Beranda, Transaksi, Utang, Laporan.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  bool loading = true;
  String? error;

  User? user;
  Map<String, dynamic> dashboard = {};
  List<dynamic> recentTransactions = [];
  List<Wallet> wallets = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final profileResponse = await ApiService.getProfile();
      final profileData = Map<String, dynamic>.from(
        profileResponse['data'] ?? {},
      );

      final dashboardResponse = await ApiService.getDashboardStats();

      List<dynamic> txs = [];
      try {
        txs = await ApiService.getTransactions();
        txs.sort((a, b) {
          final dateA = parseDateTime(a['created_at'], a['date']);
          final dateB = parseDateTime(b['created_at'], b['date']);
          return dateB.compareTo(dateA);
        });
      } catch (_) {}

      List<Wallet> loadedWallets = [];
      try {
        final walletRes = await ApiService.getWallets();
        final rawWallets = walletRes['wallets'] as List? ?? [];
        for (var item in rawWallets) {
          if (item is Map<String, dynamic>) {
            loadedWallets.add(Wallet.fromJson(item));
          }
        }
      } catch (_) {}

      setState(() {
        user = User.fromJson(profileData);
        dashboard = _extractDashboard(dashboardResponse);
        recentTransactions = txs.take(5).toList();
        wallets = loadedWallets;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  Map<String, dynamic> _extractDashboard(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    return response;
  }

  void changePage(int index) {
    setState(() => selectedIndex = index);
  }

  // ── Build ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: selectedIndex,
        children: _buildPages(),
      ),
      floatingActionButton: selectedIndex == 0
          ? Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChatBotPage(),
                    ),
                  );
                  if (result == true) {
                    await loadData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5), // Deep Indigo Brand
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'FinChat',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: .3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981), // Emerald dot indicator
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  List<Widget> _buildPages() {
    return [
      _buildHomeTab(),
      const TransactionsPage(),
      const UtangPiutangPage(),
      const ReportsPage(),
    ];
  }

  // ── AppBar ────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B4DFF),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    _pageIcon(),
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FinChat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      _pageSubtitle(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Stack(
            children: [
              const Icon(Icons.notifications_none_rounded, size: 24),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981), // Emerald dot
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 4),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(user: user ?? User(name: 'Pengguna', email: '-')),
                ),
              );
            },
            child: CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFFEEF2FF),
              child: Text(
                (user?.name.isNotEmpty == true ? user!.name[0] : 'U').toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom Nav ────────────────────────────────────

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: changePage,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Transaksi',
        ),
        NavigationDestination(
          icon: Icon(Icons.handshake_outlined),
          selectedIcon: Icon(Icons.handshake),
          label: 'Utang',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart_rounded),
          label: 'Laporan',
        ),
      ],
    );
  }

  // ── Home Tab ──────────────────────────────────────

  Widget _buildHomeTab() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          children: [
            const SizedBox(height: 180),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 50),
                    const SizedBox(height: 16),
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: loadData,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return HomeBody(
      name: user?.name ?? 'Pengguna',
      dashboard: dashboard,
      recentTransactions: recentTransactions,
      onRefresh: loadData,
      onChangePage: changePage,
    );
  }

  // ── Helpers ───────────────────────────────────────

  String _pageSubtitle() {
    switch (selectedIndex) {
      case 1: return 'Transaksi';
      case 2: return 'Utang & Piutang';
      case 3: return 'Laporan Keuangan';
      default: return 'Beranda';
    }
  }

  IconData _pageIcon() => Icons.chat_bubble_rounded;
}
