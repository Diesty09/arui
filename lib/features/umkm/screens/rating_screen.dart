import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../../models/rating_model.dart';
import '../../../services/firestore_service.dart';
import '../../../providers/auth_provider.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final String campaignId;
  final String influencerId;

  const RatingScreen({
    super.key,
    required this.campaignId,
    required this.influencerId,
  });

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _rating = 0;
  final _reviewController = TextEditingController();
  bool _isLoading = false;

  void _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap berikan bintang rating')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) throw Exception('User error');

      final ratingModel = RatingModel(
        ratingId: '',
        campaignId: widget.campaignId,
        umkmId: user.uid,
        influencerId: widget.influencerId,
        ratingValue: _rating,
        reviewText: _reviewController.text,
      );

      await FirestoreService().createRating(ratingModel);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ulasan berhasil dikirim. Terima kasih!')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim ulasan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beri Ulasan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.star_border, size: 80, color: Colors.orange),
            const SizedBox(height: 16),
            Text('Bagaimana hasil kerja sama ini?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Memberikan ulasan akan menandai project sebagai selesai.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: Colors.orange,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 32),
            
            CustomTextField(
              label: 'Ulasan Anda',
              hint: 'Tuliskan pengalaman Anda bekerja sama dengan influencer ini...',
              controller: _reviewController,
              maxLines: 5,
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRating,
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Kirim Ulasan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
