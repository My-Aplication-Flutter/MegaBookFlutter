import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './Models/Section.dart';
import 'Screens/MyHomePage.dart';
import 'Screens/Livres/Livres.dart';
import 'Screens/Magazines/Magazines.dart';
import 'Screens/FavoritesLivres.dart'; // importe ta page favoris
import 'Screens/FavoritesMagazines.dart'; // importe ta page favoris
import 'Screens/LoginPage.dart'; // importe ta page login
import 'Screens/Magazines/OfflineLibraryPage.dart';
import 'Screens/Favoris.dart';
/*import './FavoritesPage.dart';
import './OfflineArticlesPage.dart';
import './ProfilePage.dart';
import './SettingsPage.dart';
import './LoginPage.dart';*/

final List<Section> sections = [
  Section(key: "Livres", value: "Livres", activation: "1"),
  Section(key: "Magazines", value: "Magazines", activation: "1"),
];

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  String? selectedKey;
  final Set<String> expandedSections = {'account', 'categories', 'system'};

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      await prefs.remove('token');
      await prefs.remove('user');

      print("LOGOUT OK");

      if (!mounted) {
        print("Widget non monté");
        return;
      }

      // 🔥 IMPORTANT si appelé depuis modal / drawer
      Navigator.of(context).popUntil((route) => route.isFirst);

      // 🔥 NAVIGATION ROOT
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      print("Erreur logout: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur logout : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      width: 340,
      backgroundColor: const Color(0xFFF6F7FB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                children: [
                  _sectionLabel("Navigation", theme),
                  _buildSimpleItem(
                    context,
                    icon: Icons.home_rounded,
                    color: Colors.blue,
                    title: 'Accueil',
                    subtitle: 'Retour à la page principale',
                    selected: selectedKey == 'home',
                    onTap: () {
                      setState(() => selectedKey = 'home');
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildExpansionSection(
                    context,
                    keyId: 'account',
                    title: 'Mon compte',
                    icon: Icons.manage_accounts_rounded,
                    color: const Color(0xFF7C3AED),
                    children: [
                      _buildSimpleItem(
                        context,
                        icon: Icons.person_rounded,
                        color: const Color(0xFF7C3AED),
                        title: 'Mon profil',
                        subtitle: 'Gérer mes informations',
                        selected: selectedKey == 'profile',
                        onTap: () {
                          setState(() => selectedKey = 'profile');
                          Navigator.pop(context);
                          /* Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>  const ProfilePage(),
                            ),
                          );*/
                        },
                      ),
                      _buildSimpleItem(
                        context,
                        icon: Icons.favorite_rounded,
                        color: const Color(0xFFEC4899),
                        title: 'Articles favoris',
                        subtitle: 'Articles sauvegardés',
                        badge: '12',
                        selected: selectedKey == 'favorites',
                        onTap: () {
                          setState(() => selectedKey = 'favorites');
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FavoritesPage(),
                            ),
                          );
                        },
                      ),
                      _buildSimpleItem(
                        context,
                        icon: Icons.download_rounded,
                        color: const Color(0xFF0EA5A5),
                        title: 'Articles offline',
                        subtitle: 'Lire sans connexion',
                        badge: '4',
                        selected: selectedKey == 'offline',
                        onTap: () {
                          setState(() => selectedKey = 'offline');
                          /* Navigator.pop(context);
                         Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>   const OfflineArticlesPage(),//
                            ),
                          );*/
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildExpansionSection(
                    context,
                    keyId: 'categories',
                    title: 'Catégories',
                    icon: Icons.category_rounded,
                    color: const Color(0xFF0F766E),
                    children: [
                      ...sections.where((s) => s.activation == "1").map(
                            (section) => _buildSimpleItem(
                              context,
                              icon: _getIcon(section.key),
                              color: _getColor(section.key),
                              title: section.value,
                              subtitle: "",
                              selected: selectedKey == section.key,
                              onTap: () {
                                setState(() => selectedKey = section.key);
                                Navigator.pop(context);
                                if (selectedKey == "Livres") {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const Livres(),
                                    ),
                                  );
                                }
                                if (selectedKey == "Magazines") {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const Magazines(),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildExpansionSection(
                    context,
                    keyId: 'system',
                    title: 'Système',
                    icon: Icons.settings_rounded,
                    color: const Color(0xFF6B7280),
                    children: [
                      _buildSimpleItem(
                        context,
                        icon: Icons.settings_rounded,
                        color: const Color(0xFF6B7280),
                        title: 'Paramètres',
                        subtitle: 'Langue, thème, préférences',
                        selected: selectedKey == 'settings',
                        onTap: () {
                          setState(() => selectedKey = 'settings');
                          Navigator.pop(context);
                          /* Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsPage(),
                            ),
                          );*/
                        },
                      ),
                      _buildSimpleItem(
                        context,
                        icon: Icons.logout_rounded,
                        color: const Color(0xFFDC2626),
                        title: 'Déconnexion',
                        subtitle: 'Fermer la session utilisateur',
                        selected: selectedKey == 'logout',
                        onTap: () async {
                          setState(() => selectedKey = 'logout');
                          Navigator.pop(context);

                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Déconnexion'),
                              content: const Text(
                                'Voulez-vous vraiment vous déconnecter ?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Annuler'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Déconnecter'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await _logout();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 30,
              backgroundImage:
                  NetworkImage('https://i.postimg.cc/DZ0yxfQK/user.png'),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue 👋',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Une navigation claire et rapide',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 10, top: 6),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildExpansionSection(
    BuildContext context, {
    required String keyId,
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    final isExpanded = expandedSections.contains(keyId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey<String>(keyId),
            initiallyExpanded: isExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                if (expanded) {
                  expandedSections.add(keyId);
                } else {
                  expandedSections.remove(keyId);
                }
              });
            },
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            collapsedShape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            leading: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            subtitle: Text(
              keyId == 'account'
                  ? 'Profil, favoris et hors ligne'
                  : keyId == 'system'
                      ? 'Paramètres et session'
                      : 'Parcourir les rubriques',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade600,
              ),
            ),
            trailing: AnimatedRotation(
              turns: isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: color,
                size: 28,
              ),
            ),
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color.withOpacity(0.28) : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: selected ? color : color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: selected ? Colors.white : color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: selected ? color : const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12.3,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: color,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    Icons.chevron_right_rounded,
                    color: selected ? color : Colors.grey.shade400,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.newspaper_rounded,
                color: Colors.grey.shade700, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Navigation premium avec paramètres et sécurité',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _getIcon(String key) {
    switch (key) {
      case 'international_politique':
        return Icons.public_rounded;
      case 'informatique':
        return Icons.computer_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'criminalite':
        return Icons.gavel_rounded;
      case 'crypto_monnaie':
        return Icons.currency_bitcoin_rounded;
      case 'News-Arabic':
        return Icons.language_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  static Color _getColor(String key) {
    switch (key) {
      case 'international_politique':
        return const Color(0xFF2563EB);
      case 'informatique':
        return const Color(0xFF4F46E5);
      case 'science':
        return const Color(0xFF16A34A);
      case 'criminalite':
        return const Color(0xFFDC2626);
      case 'crypto_monnaie':
        return const Color(0xFFF59E0B);
      case 'News-Arabic':
        return const Color(0xFF0F766E);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
