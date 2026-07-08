import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Temukan Influencer Tepat',
      'description': 'UMKM dapat mencari influencer yang sesuai dengan target pasar dan budget.',
      'icon': 'search',
    },
    {
      'title': 'Promosikan Produk Anda',
      'description': 'Influencer dapat menemukan berbagai tawaran promosi menarik dari UMKM.',
      'icon': 'campaign',
    },
    {
      'title': 'Kolaborasi Mudah',
      'description': 'Chat, tawarkan harga, bayar, dan selesaikan project dalam satu aplikasi.',
      'icon': 'handshake',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          index == 0 ? Icons.search : (index == 1 ? Icons.campaign : Icons.handshake),
                          size: 120,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 48),
                        Text(
                          _pages[index]['title']!,
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _pages[index]['description']!,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Theme.of(context).primaryColor : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      context.go('/role-selection');
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    }
                  },
                  child: Text(_currentPage == _pages.length - 1 ? 'Mulai Sekarang' : 'Lanjut'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
