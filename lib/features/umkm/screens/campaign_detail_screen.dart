import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/campaign_model.dart';
import '../../../models/offer_model.dart';
import '../../../services/firestore_service.dart';

final offersProvider = StreamProvider.family.autoDispose<List<OfferModel>, String>((ref, campaignId) {
  final firestoreService = FirestoreService();
  return firestoreService.getOffersForCampaign(campaignId);
});

class CampaignDetailScreen extends ConsumerWidget {
  final CampaignModel campaign;

  const CampaignDetailScreen({super.key, required this.campaign});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(offersProvider(campaign.campaignId));
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Campaign'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).primaryColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.title,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white, fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Status: ${campaign.status.toUpperCase()} (${campaign.targetInfluencerCount} Influencer)',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
            // Detail Information
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Detail Produk'),
                  Text(campaign.productDescription),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow('Budget', formatCurrency.format(campaign.budget)),
                  _buildInfoRow('Platform', campaign.platform),
                  _buildInfoRow('Jenis Promosi', campaign.promotionType),
                  _buildInfoRow('Target Pasar', campaign.targetMarket),
                  _buildInfoRow('Durasi', campaign.duration),
                  _buildInfoRow('Deadline', DateFormat('dd MMM yyyy').format(campaign.deadline)),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Penawaran Masuk'),
                  
                  // Daftar Penawaran
                  offersAsync.when(
                    data: (offers) {
                      if (offers.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text('Belum ada penawaran dari influencer.'),
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: offers.length,
                        itemBuilder: (context, index) {
                          final offer = offers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(offer.influencerName),
                              subtitle: Text('${formatCurrency.format(offer.offerPrice)} - ${offer.estimatedDuration}'),
                              trailing: Chip(label: Text(offer.status, style: const TextStyle(fontSize: 10))),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Detail Penawaran'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Influencer: ${offer.influencerName}'),
                                        const SizedBox(height: 8),
                                        Text('Pesan: ${offer.note}'),
                                        const SizedBox(height: 8),
                                        Text('Harga: ${formatCurrency.format(offer.offerPrice)}'),
                                        const SizedBox(height: 8),
                                        Text('Estimasi: ${offer.estimatedDuration}'),
                                      ],
                                    ),
                                    actions: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                        label: const Text('Chat'),
                                        onPressed: () async {
                                          context.pop(); // Close dialog
                                          try {
                                            final chatId = await FirestoreService().getOrCreateChatRoom(
                                              offer.campaignId,
                                              campaign.umkmId,
                                              offer.influencerId,
                                            );
                                            if (context.mounted) {
                                              context.push('/chat/room', extra: {
                                                'chatId': chatId,
                                                'targetName': offer.influencerName,
                                                'campaignId': offer.campaignId,
                                                'targetId': offer.influencerId,
                                                'umkmId': campaign.umkmId,
                                              });
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Gagal memulai chat: $e'),
                                                  backgroundColor: Colors.red.shade700,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                      if (offer.status == 'menunggu' && campaign.status == 'aktif') ...[
                                        TextButton(
                                          onPressed: () => context.pop(),
                                          child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            context.pop();
                                            context.push('/umkm/payment', extra: {
                                              'campaignId': offer.campaignId,
                                              'influencerId': offer.influencerId,
                                              'amount': offer.offerPrice,
                                            });
                                          },
                                          child: const Text('Terima & Bayar'),
                                        ),
                                      ] else if (offer.status == 'draft_dikirim') ...[
                                        TextButton(
                                          onPressed: () => context.pop(),
                                          child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            context.pop();
                                            context.push('/umkm/review-draft', extra: offer);
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                          child: const Text('Review Draft'),
                                        ),
                                      ] else if (offer.status == 'selesai') ...[
                                        TextButton(
                                          onPressed: () => context.pop(),
                                          child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            context.pop();
                                            context.push('/umkm/rating', extra: {
                                              'campaignId': offer.campaignId,
                                              'influencerId': offer.influencerId,
                                              'amount': offer.offerPrice,
                                            });
                                          },
                                          child: const Text('Beri Ulasan'),
                                        ),
                                      ] else if (offer.status == 'diterima' || offer.status == 'draft_revisi' || offer.status == 'draft_acc') ...[
                                        TextButton(
                                          onPressed: () => context.pop(),
                                          child: const Text('Tutup'),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.only(left: 8.0),
                                          child: Text('Menunggu Influencer', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                                        ),
                                      ] else ...[
                                        TextButton(
                                          onPressed: () => context.pop(),
                                          child: const Text('Tutup'),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Error: $e'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: (campaign.status == 'aktif' || campaign.status == 'proses')
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Tandai Campaign Selesai'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Konfirmasi'),
                      content: const Text(
                        'Tandai campaign ini sebagai SELESAI?\n\nPastikan semua influencer sudah menyelesaikan pekerjaan mereka.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => ctx.pop(),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () async {
                            ctx.pop();
                            try {
                              await FirestoreService().updateCampaignStatus(campaign.campaignId, 'selesai');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Campaign berhasil ditandai selesai!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                context.pop();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Ya, Selesaikan', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          : null,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
