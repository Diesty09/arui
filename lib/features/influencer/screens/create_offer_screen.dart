import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../../models/campaign_model.dart';
import '../../../models/offer_model.dart';
import '../../../services/firestore_service.dart';
import '../../../providers/auth_provider.dart';

class CreateOfferScreen extends ConsumerStatefulWidget {
  final CampaignModel campaign;

  const CreateOfferScreen({super.key, required this.campaign});

  @override
  ConsumerState<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends ConsumerState<CreateOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _noteController = TextEditingController();
  final _descController = TextEditingController();

  // IG Fields
  final _igUserCont = TextEditingController();
  final _igFollowersCont = TextEditingController();
  final _igLinkCont = TextEditingController();
  final _igCategoryCont = TextEditingController();
  final _igErCont = TextEditingController();

  // Tiktok Fields
  final _ttUserCont = TextEditingController();
  final _ttFollowersCont = TextEditingController();
  final _ttLinkCont = TextEditingController();
  final _ttCategoryCont = TextEditingController();
  final _ttErCont = TextEditingController();

  // KOL Personal Info
  final _kolNameCont = TextEditingController();
  final _kolAgeCont = TextEditingController();
  final _domicileCont = TextEditingController();
  final _addressCont = TextEditingController();
  final _phoneCont = TextEditingController();

  // Dropdown / Radio selections
  String _gender = 'Female Hijab';

  // Support Us checklist
  bool _followedDiesty = false;
  bool _followedArui = false;
  bool _followedBeauty = false;
  
  bool _isLoading = false;
  bool _isAgreed = false;

  @override
  void dispose() {
    _priceController.dispose();
    _durationController.dispose();
    _noteController.dispose();
    _descController.dispose();
    
    _igUserCont.dispose();
    _igFollowersCont.dispose();
    _igLinkCont.dispose();
    _igCategoryCont.dispose();
    _igErCont.dispose();
    
    _ttUserCont.dispose();
    _ttFollowersCont.dispose();
    _ttLinkCont.dispose();
    _ttCategoryCont.dispose();
    _ttErCont.dispose();
    
    _kolNameCont.dispose();
    _kolAgeCont.dispose();
    _domicileCont.dispose();
    _addressCont.dispose();
    _phoneCont.dispose();
    
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka link: $urlString')),
        );
      }
    }
  }

  Widget _buildPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.purple.shade900, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, height: 1.4, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAgreementPoints() {
    return [
      _buildPoint('Bersedia menyelesaikan tanggung jawab job tepat waktu.'),
      _buildPoint('Bersedia dengan fee yang telah ditetapkan.'),
      _buildPoint('Bersedia melakukan revisi hingga draft dinyatakan approved oleh Client.'),
      _buildPoint('Siap dengan deadline yang diberikan dan bersedia dikenakan potongan fee apabila melewati batas waktu drafting/posting/insight:'),
      _buildPoint('Denda 5x harga produk jika terlambat lebih dari 2 hari.'),
      _buildPoint('Potongan Rp5.000/hari jika melewati deadline yang diberikan.'),
      _buildPoint('Bersedia denda 5x lipat fee dan ganti rugi 5x lipat harga produk apabila cancel atau mangkir setelah dinyatakan lolos job.'),
      _buildPoint('Konten yang sudah diposting menjadi milik penuh Client/Brand.'),
      _buildPoint('Jika di tengah campaign terdapat perubahan SOW, fee, atau rules, maka talent wajib mengikuti ketentuan baru yang diberlakukan.'),
      _buildPoint('Management partner akan menjadi penanggung jawab selama job berlangsung.'),
    ];
  }

  Widget _buildInstagramLink({required String label, required String url}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _launchUrl(url),
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.pink.shade50.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.pink.shade100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt_outlined, size: 18, color: Colors.pink.shade700),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade800,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.open_in_new_rounded, size: 12, color: Colors.pink.shade400),
            ],
          ),
        ),
      ),
    );
  }

  void _submitOffer() async {
    if (!_followedDiesty || !_followedArui || !_followedBeauty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap ikuti/dukung ketiga akun Instagram kami terlebih dahulu'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final user = await ref.read(currentUserProvider.future);
        if (user == null) throw Exception('User tidak valid');

        final offer = OfferModel(
          offerId: '',
          campaignId: widget.campaign.campaignId,
          umkmId: widget.campaign.umkmId,
          influencerId: user.uid,
          influencerName: user.name,
          offerDescription: 'Penawaran untuk campaign ${widget.campaign.title}',
          offerPrice: widget.campaign.budget,
          estimatedDuration: widget.campaign.duration,
          note: '',
          status: 'menunggu',
          instagramUsername: _igUserCont.text,
          instagramFollowers: _igFollowersCont.text,
          instagramLink: _igLinkCont.text,
          instagramCategory: _igCategoryCont.text,
          instagramEr: _igErCont.text,
          tiktokUsername: _ttUserCont.text,
          tiktokFollowers: _ttFollowersCont.text,
          tiktokLink: _ttLinkCont.text,
          tiktokCategory: _ttCategoryCont.text,
          tiktokEr: _ttErCont.text,
          kolFullName: _kolNameCont.text,
          kolAge: _kolAgeCont.text,
          gender: _gender,
          domicile: _domicileCont.text,
          fullAddress: _addressCont.text,
          phoneNumber: _phoneCont.text,
          jobInfo: 'ARUI MG',
          handleBy: 'ARUI MG',
          waMgNumber: '0895335038939',
        );

        await FirestoreService().createOffer(offer);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penawaran berhasil dikirim ke UMKM!')),
        );
        context.go('/influencer/home'); // Kembali ke home setelah berhasil
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim penawaran: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Penawaran')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Anda sedang menawar untuk campaign "${widget.campaign.title}" dengan budget maksimal Rp ${widget.campaign.budget}.',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              _buildSectionCard(
                title: '1. Informasi Instagram',
                children: [
                  CustomTextField(
                    label: 'Username Instagram',
                    hint: 'Cth: @diesty_arwid',
                    controller: _igUserCont,
                    validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Jumlah Followers Instagram',
                    hint: 'Cth: 10.5k',
                    controller: _igFollowersCont,
                    validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Link Akun Instagram',
                    hint: 'Cth: https://www.instagram.com/diesty_arwid',
                    controller: _igLinkCont,
                    validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Kategori Konten Instagram',
                    hint: 'Cth: Beauty, Fashion, Food, etc.',
                    controller: _igCategoryCont,
                    validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Engagement Rate (ER) Instagram %',
                    hint: 'Cth: 4.5%',
                    controller: _igErCont,
                    validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                  ),
                ],
              ),

              _buildSectionCard(
                title: '2. Informasi Tiktok',
                children: [
                  CustomTextField(
                    label: 'Username Tiktok',
                    hint: 'Cth: @username_tiktok',
                    controller: _ttUserCont,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Jumlah Followers Tiktok',
                    hint: 'Cth: 20k',
                    controller: _ttFollowersCont,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Link Akun Tiktok',
                    hint: 'Cth: https://www.tiktok.com/@username',
                    controller: _ttLinkCont,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Kategori Konten Tiktok',
                    hint: 'Cth: Beauty, Fashion, Food, etc.',
                    controller: _ttCategoryCont,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Engagement Rate (ER) Tiktok %',
                    hint: 'Cth: 5%',
                    controller: _ttErCont,
                  ),
                ],
              ),

              _buildSectionCard(
                title: '3. Data Pribadi KOL / Talent',
                children: [
                  CustomTextField(
                    label: 'Nama Lengkap KOL',
                    hint: 'Masukkan nama sesuai KTP',
                    controller: _kolNameCont,
                    validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Usia KOL',
                    hint: 'Cth: 23',
                    controller: _kolAgeCont,
                    keyboardType: TextInputType.number,
                    validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Female Hijab', child: Text('Female Hijab')),
                      DropdownMenuItem(value: 'Female Non Hijab', child: Text('Female Non Hijab')),
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                    ],
                    onChanged: (val) => setState(() => _gender = val ?? 'Female Hijab'),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Domisili',
                    hint: 'Cth: Jakarta Selatan',
                    controller: _domicileCont,
                    validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Alamat Lengkap KOL',
                    hint: 'Masukkan alamat pengiriman produk...',
                    controller: _addressCont,
                    maxLines: 3,
                    validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'No HP / WhatsApp Talent',
                    hint: 'Cth: 081234567890',
                    controller: _phoneCont,
                    keyboardType: TextInputType.phone,
                    validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                  ),
                ],
              ),

              _buildSectionCard(
                title: '4. Detail Penanggung Jawab',
                children: [
                  TextFormField(
                    initialValue: 'ARUI MG',
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Info Job',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: 'ARUI MG',
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Handle By',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: '0895335038939',
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'No WA Management',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              
              _buildSectionCard(
                title: '5. Perjanjian Job Arui Management',
                children: [
                  Text(
                    'Jika ada talent yang menghubungi Brand secara pribadi, menjelekkan nama Arui Management dan naungan dari Arui Management, mempermasalahkan fee kepada Brand, atau mengunggah hal negatif terkait job/agency ke media sosial, maka talent tersebut akan di-blacklist dari seluruh brand and management, fee tidak akan dibayarkan, dan dapat dilakukan tuntutan perdata untuk ganti rugi.',
                    style: TextStyle(fontSize: 12, height: 1.5, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dengan ini, saya menyatakan bahwa saya telah memahami kriteria, Scope of Work (SOW), dan benefit job yang telah diinformasikan. Maka secara sadar dan tanpa paksaan saya mengisi Form Job dan MENYETUJUI isi PERJANJIAN JOB Arui Management sebagai berikut:',
                    style: TextStyle(fontSize: 12, height: 1.5, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'KETENTUAN JOB',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._buildAgreementPoints(),
                  const SizedBox(height: 16),
                  Text(
                    'PERNYATAAN PERSETUJUAN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dengan mengisi form ini, saya menyatakan bahwa saya telah membaca, memahami, dan menyetujui seluruh isi PERJANJIAN JOB Arui Management tanpa paksaan dari pihak mana pun. Saya siap mematuhi seluruh aturan dan menerima konsekuensi sesuai ketentuan apabila terjadi pelanggaran.',
                    style: TextStyle(fontSize: 12, height: 1.5, color: Colors.grey.shade800),
                  ),
                  const Divider(height: 32),
                  CheckboxListTile(
                    value: _isAgreed,
                    onChanged: (val) {
                      setState(() {
                        _isAgreed = val ?? false;
                      });
                    },
                    title: const Text(
                      'Saya Bertanggung Jawab Penuh Atas Job Dan Bersedia Denda Sesuai Aturan Yang Tertera.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ],
              ),

              _buildSectionCard(
                title: '6. Dukung / Follow Media Sosial Kami',
                children: [
                  const Text(
                    'Buka masing-masing link berikut lalu centang konfirmasi follow:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _followedDiesty,
                        onChanged: (val) => setState(() => _followedDiesty = val ?? false),
                      ),
                      Expanded(
                        child: _buildInstagramLink(
                          label: 'Follow diesty_arwid',
                          url: 'https://www.instagram.com/diesty_arwid',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _followedArui,
                        onChanged: (val) => setState(() => _followedArui = val ?? false),
                      ),
                      Expanded(
                        child: _buildInstagramLink(
                          label: 'Follow arui.management',
                          url: 'https://www.instagram.com/arui.management',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _followedBeauty,
                        onChanged: (val) => setState(() => _followedBeauty = val ?? false),
                      ),
                      Expanded(
                        child: _buildInstagramLink(
                          label: 'Follow beautycomunity_',
                          url: 'https://www.instagram.com/beautycomunity_',
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isLoading || !_isAgreed || !_followedDiesty || !_followedArui || !_followedBeauty) ? null : _submitOffer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Kirim Penawaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade900,
              ),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}
