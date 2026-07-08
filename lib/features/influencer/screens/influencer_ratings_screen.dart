import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/rating_model.dart';
import '../../../services/firestore_service.dart';
import '../../../providers/auth_provider.dart';

final influencerRatingsProvider = StreamProvider.autoDispose<List<RatingModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return FirestoreService().getRatingsForInfluencer(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

class InfluencerRatingsScreen extends ConsumerWidget {
  final String? influencerId;

  const InfluencerRatingsScreen({super.key, this.influencerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatDate = DateFormat('dd MMM yyyy', 'id_ID');
    final targetUid = influencerId ?? ref.watch(currentUserProvider).value?.uid;

    if (targetUid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rating & Ulasan')),
      body: StreamBuilder<List<RatingModel>>(
        stream: FirestoreService().getRatingsForInfluencer(targetUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final ratings = snapshot.data ?? [];
          if (ratings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Belum ada ulasan', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Ulasan dari UMKM akan muncul di sini setelah kerja sama selesai',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                ],
              ),
            );
          }

          final avgRating = ratings.fold(0.0, (sum, r) => sum + r.ratingValue) / ratings.length;

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF3CD), Color(0xFFFFE082)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(avgRating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF6D4C00))),
                            const SizedBox(width: 8),
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 36),
                          ],
                        ),
                        Text('Dari ${ratings.length} ulasan',
                          style: const TextStyle(color: Color(0xFF8B6000), fontSize: 13)),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [5, 4, 3, 2, 1].map((star) {
                          final count = ratings.where((r) => r.ratingValue == star).length;
                          final fraction = ratings.isEmpty ? 0.0 : count / ratings.length;
                          return Row(
                            children: [
                              Text('$star', style: const TextStyle(fontSize: 12, color: Color(0xFF6D4C00))),
                              const SizedBox(width: 4),
                              const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                              const SizedBox(width: 4),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: fraction,
                                    backgroundColor: Colors.amber.shade100,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text('$count', style: const TextStyle(fontSize: 11, color: Color(0xFF8B6000))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: ratings.length,
                  itemBuilder: (context, index) {
                    final rating = ratings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 18,
                                  child: Icon(Icons.store, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('UMKM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      if (rating.createdAt != null)
                                        Text(formatDate.format(rating.createdAt!),
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: List.generate(5, (i) => Icon(
                                    i < rating.ratingValue ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: Colors.amber,
                                    size: 20,
                                  )),
                                ),
                              ],
                            ),
                            if (rating.reviewText.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(rating.reviewText, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
