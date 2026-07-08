import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';

// UMKM Screens
import '../../features/umkm/screens/umkm_main_layout.dart' as umkm_layout;
import '../../features/umkm/screens/umkm_home_screen.dart' as umkm_home;
import '../../features/umkm/screens/umkm_profile_screen.dart' as umkm_profile;
import '../../features/umkm/screens/edit_umkm_profile_screen.dart' as edit_umkm_profile;
import '../../features/umkm/screens/create_campaign_screen.dart' as create_campaign;
import '../../features/umkm/screens/campaign_list_screen.dart' as campaign_list;
import '../../features/umkm/screens/campaign_detail_screen.dart' as campaign_detail;
import '../../features/umkm/screens/influencer_list_screen.dart' as influencer_list;
import '../../features/umkm/screens/review_draft_screen.dart' as review_draft;
// Influencer Screens
import '../../features/influencer/screens/influencer_main_layout.dart' as influencer_layout;
import '../../features/influencer/screens/influencer_home_screen.dart' as influencer_home;
import '../../features/influencer/screens/campaign_browse_screen.dart' as campaign_browse;
import '../../features/influencer/screens/campaign_detail_for_influencer_screen.dart' as campaign_detail_influencer;
import '../../features/influencer/screens/create_offer_screen.dart' as create_offer;
import '../../features/influencer/screens/influencer_profile_screen.dart' as influencer_profile;
import '../../features/influencer/screens/edit_influencer_profile_screen.dart' as edit_influencer_profile;
import '../../features/influencer/screens/influencer_payment_screen.dart' as influencer_payment;
import '../../features/influencer/screens/influencer_work_history_screen.dart' as influencer_work_history;
import '../../features/influencer/screens/influencer_ratings_screen.dart' as influencer_ratings;
import '../../features/influencer/screens/influencer_appeal_screen.dart' as influencer_appeal;
import '../../features/influencer/screens/submit_draft_screen.dart' as submit_draft;
import '../../features/influencer/screens/submit_final_content_screen.dart' as submit_final;

// Chat Screens
import '../../features/chat/screens/chat_list_screen.dart' as chat_list;
import '../../features/chat/screens/chat_room_screen.dart' as chat_room;

// Payment & Rating
import '../../features/umkm/screens/payment_screen.dart' as payment_screen;
import '../../features/umkm/screens/rating_screen.dart' as rating_screen;
import '../../features/umkm/screens/umkm_transaction_history_screen.dart' as umkm_transactions;
import '../../features/umkm/screens/umkm_account_settings_screen.dart' as umkm_settings;

// Admin Screens
import '../../features/admin/screens/admin_dashboard_screen.dart' as admin_dashboard;
import '../../features/admin/screens/manage_payment_screen.dart' as admin_payments;
import '../../features/admin/screens/admin_payment_config_screen.dart' as admin_payment_config;
import '../../features/admin/screens/admin_manage_umkm_screen.dart' as admin_manage_umkm;
import '../../features/admin/screens/admin_manage_influencer_screen.dart' as admin_manage_influencer;
import '../../features/admin/screens/admin_manage_campaigns_screen.dart' as admin_manage_campaigns;
import '../../features/admin/screens/admin_blacklist_screen.dart' as admin_blacklist;
import '../../shared/screens/notification_list_screen.dart' as notifications;

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final role = state.extra as String? ?? 'umkm';
          return LoginScreen(role: role);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final role = state.extra as String? ?? 'umkm';
          return RegisterScreen(role: role);
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return child; // We'll wrap with UmkmMainLayout for umkm routes
        },
        routes: [
          GoRoute(
            path: '/umkm/home',
            builder: (context, state) => const umkm_layout.UmkmMainLayout(
              child: umkm_home.UmkmHomeScreen(),
            ),
          ),
          GoRoute(
            path: '/umkm/campaigns',
            builder: (context, state) => const umkm_layout.UmkmMainLayout(
              child: campaign_list.CampaignListScreen(),
            ),
          ),
          GoRoute(
            path: '/umkm/profile',
            builder: (context, state) => const umkm_layout.UmkmMainLayout(
              child: umkm_profile.UmkmProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/umkm/influencers',
        builder: (context, state) => const influencer_list.InfluencerListScreen(),
      ),
      GoRoute(
        path: '/umkm/influencers/profile',
        builder: (context, state) {
          final influencerId = state.extra as String;
          return influencer_profile.InfluencerProfileScreen(influencerId: influencerId);
        },
      ),
      GoRoute(
        path: '/umkm/profile/edit',
        builder: (context, state) => const edit_umkm_profile.EditUmkmProfileScreen(),
      ),
      GoRoute(
        path: '/umkm/campaigns/create',
        builder: (context, state) => const create_campaign.CreateCampaignScreen(),
      ),
      GoRoute(
        path: '/umkm/campaigns/detail',
        builder: (context, state) {
          final campaign = state.extra as dynamic;
          return campaign_detail.CampaignDetailScreen(campaign: campaign);
        },
      ),
      
      // Influencer routes
      ShellRoute(
        builder: (context, state, child) {
          return child;
        },
        routes: [
          GoRoute(
            path: '/influencer/home',
            builder: (context, state) => const influencer_layout.InfluencerMainLayout(
              child: influencer_home.InfluencerHomeScreen(),
            ),
          ),
          GoRoute(
            path: '/influencer/browse',
            builder: (context, state) => const influencer_layout.InfluencerMainLayout(
              child: campaign_browse.CampaignBrowseScreen(),
            ),
          ),
          GoRoute(
            path: '/influencer/profile',
            builder: (context, state) => const influencer_layout.InfluencerMainLayout(
              child: influencer_profile.InfluencerProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/influencer/campaigns/detail',
        builder: (context, state) {
          final campaign = state.extra as dynamic;
          return campaign_detail_influencer.CampaignDetailForInfluencerScreen(campaign: campaign);
        },
      ),
      GoRoute(
        path: '/influencer/campaigns/offer',
        builder: (context, state) {
          final campaign = state.extra as dynamic;
          return create_offer.CreateOfferScreen(campaign: campaign);
        },
      ),
      GoRoute(
        path: '/influencer/profile/edit',
        builder: (context, state) => const edit_influencer_profile.EditInfluencerProfileScreen(),
      ),
      GoRoute(
        path: '/influencer/payments',
        builder: (context, state) => const influencer_payment.InfluencerPaymentScreen(),
      ),
      GoRoute(
        path: '/influencer/work-history',
        builder: (context, state) => const influencer_work_history.InfluencerWorkHistoryScreen(),
      ),
      GoRoute(
        path: '/influencer/ratings',
        builder: (context, state) {
          final influencerId = state.extra as String?;
          return influencer_ratings.InfluencerRatingsScreen(influencerId: influencerId);
        },
      ),
      GoRoute(
        path: '/influencer/appeal',
        builder: (context, state) => const influencer_appeal.InfluencerAppealScreen(),
      ),
      GoRoute(
        path: '/influencer/submit-draft',
        builder: (context, state) {
          final offer = state.extra as dynamic;
          return submit_draft.SubmitDraftScreen(offer: offer);
        },
      ),
      GoRoute(
        path: '/influencer/submit-final',
        builder: (context, state) {
          final offer = state.extra as dynamic;
          return submit_final.SubmitFinalContentScreen(offer: offer);
        },
      ),

      // Chat Routes
      GoRoute(
        path: '/chat',
        builder: (context, state) => const chat_list.ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/room',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return chat_room.ChatRoomScreen(
            chatId: data['chatId'],
            targetName: data['targetName'],
            campaignId: data['campaignId'],
            targetId: data['targetId'],
            umkmId: data['umkmId'],
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const notifications.NotificationListScreen(),
      ),

      // Payment & Rating Routes
      GoRoute(
        path: '/umkm/payment',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return payment_screen.PaymentScreen(
            campaignId: data['campaignId'],
            influencerId: data['influencerId'],
            amount: data['amount'],
          );
        },
      ),
      GoRoute(
        path: '/umkm/rating',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return rating_screen.RatingScreen(
            campaignId: data['campaignId'],
            influencerId: data['influencerId'],
          );
        },
      ),
      GoRoute(
        path: '/umkm/review-draft',
        builder: (context, state) {
          final offer = state.extra as dynamic;
          return review_draft.ReviewDraftScreen(offer: offer);
        },
      ),
      GoRoute(
        path: '/umkm/transactions',
        builder: (context, state) => const umkm_transactions.UmkmTransactionHistoryScreen(),
      ),
      GoRoute(
        path: '/umkm/settings',
        builder: (context, state) => const umkm_settings.UmkmAccountSettingsScreen(),
      ),
      
      // Admin Routes
      GoRoute(
        path: '/admin/home',
        builder: (context, state) => const admin_dashboard.AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/payments',
        builder: (context, state) => const admin_payments.ManagePaymentScreen(),
      ),
      GoRoute(
        path: '/admin/payment-config',
        builder: (context, state) => const admin_payment_config.AdminPaymentConfigScreen(),
      ),
      GoRoute(
        path: '/admin/umkm',
        builder: (context, state) => const admin_manage_umkm.AdminManageUmkmScreen(),
      ),
      GoRoute(
        path: '/admin/influencers',
        builder: (context, state) => const admin_manage_influencer.AdminManageInfluencerScreen(),
      ),
      GoRoute(
        path: '/admin/campaigns',
        builder: (context, state) => const admin_manage_campaigns.AdminManageCampaignsScreen(),
      ),
      GoRoute(
        path: '/admin/blacklist',
        builder: (context, state) => const admin_blacklist.AdminBlacklistScreen(),
      ),
    ],
  );
});
