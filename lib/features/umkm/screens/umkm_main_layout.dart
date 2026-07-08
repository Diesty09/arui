import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UmkmMainLayout extends StatefulWidget {
  final Widget child;
  
  const UmkmMainLayout({super.key, required this.child});

  @override
  State<UmkmMainLayout> createState() => _UmkmMainLayoutState();
}

class _UmkmMainLayoutState extends State<UmkmMainLayout> {
  int _currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    switch (index) {
      case 0:
        context.go('/umkm/home');
        break;
      case 1:
        context.go('/umkm/campaigns');
        break;
      case 2:
        context.go('/umkm/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine current index based on the route
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/umkm/home')) _currentIndex = 0;
    else if (location.startsWith('/umkm/campaigns')) _currentIndex = 1;
    else if (location.startsWith('/umkm/profile')) _currentIndex = 2;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Campaigns',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
