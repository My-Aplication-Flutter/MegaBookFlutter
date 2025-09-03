import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // HEADER avec dégradé moderne
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.green],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: const NetworkImage(
                    'https://i.postimg.cc/DZ0yxfQK/user.png',
                  ),
                  backgroundColor: Colors.white,
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Bienvenue 👋',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Menu principal',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // LISTE animée avec Cards
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _buildAnimatedMenuCard(
                  context,
                  icon: Icons.home,
                  color: Colors.teal,
                  title: 'Accueil',
                  route: '/',
                ),
                _buildAnimatedMenuCard(
                  context,
                  icon: Icons.menu_book,
                  color: Colors.blue,
                  title: 'Livres',
                  route: '/Livres',
                ),
                _buildAnimatedMenuCard(
                  context,
                  icon: Icons.chrome_reader_mode,
                  color: Colors.deepPurple,
                  title: 'Magazines',
                  route: '/Magazines',
                ),
                _buildAnimatedMenuCard(
                  context,
                  icon: Icons.favorite,
                  color: Colors.redAccent,
                  title: 'Favoris Livres',
                  route: '/FavorisLivres',
                ),
                _buildAnimatedMenuCard(
                  context,
                  icon: Icons.favorite_border,
                  color: Colors.pinkAccent,
                  title: 'Favoris Magazines',
                  route: '/FavorisMagazines',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Widget réutilisable pour un item animé
  Widget _buildAnimatedMenuCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String route,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios,
                  size: 18, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}
