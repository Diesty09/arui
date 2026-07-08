import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InfluencerMainLayout extends StatefulWidget {
  final Widget child;
  
  const InfluencerMainLayout({super.key, required this.child});

  @override
  State<InfluencerMainLayout> createState() => _InfluencerMainLayoutState();
}

class _InfluencerMainLayoutState extends State<InfluencerMainLayout> {
  int _currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    switch (index) {
      case 0:
        context.go('/influencer/home');
        break;
      case 1:
        context.go('/influencer/browse');
        break;
      case 2:
        context.go('/influencer/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/influencer/home')) _currentIndex = 0;
    else if (location.startsWith('/influencer/browse')) _currentIndex = 1;
    else if (location.startsWith('/influencer/profile')) _currentIndex = 2;

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
            icon: Icon(Icons.search),
            label: 'Cari Campaign',
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
