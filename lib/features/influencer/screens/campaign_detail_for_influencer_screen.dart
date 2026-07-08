import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/campaign_model.dart';

class CampaignDetailForInfluencerScreen extends StatelessWidget {
  final CampaignModel campaign;

  const CampaignDetailForInfluencerScreen({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Campaign'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.store, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(campaign.title, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 20)),
                      Text('Oleh: ${campaign.umkmName}', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Detail Produk'),
            Text(campaign.productDescription),
            const SizedBox(height: 16),
            
            _buildInfoCard(context, formatCurrency),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Target Pasar'),
            Text(campaign.targetMarket),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              context.push('/influencer/campaigns/offer', extra: campaign);
            },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: const Text('Ajukan Penawaran (Offer)'),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, NumberFormat format) {
    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildRow('Platform', campaign.platform),
            const Divider(),
            _buildRow('Jenis Promosi', campaign.promotionType),
            const Divider(),
            _buildRow('Budget UMKM', format.format(campaign.budget)),
            const Divider(),
            _buildRow('Durasi', campaign.duration),
            const Divider(),
            _buildRow('Deadline', DateFormat('dd MMM yyyy').format(campaign.deadline)),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
