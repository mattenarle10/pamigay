/// This file serves as a centralized export point for all screens in the app
/// It follows the role-based organization structure:
/// - common: screens shared by all user roles
/// - restaurant: screens specific to restaurant users
/// - organization: screens specific to organization users

// Common screens
export 'common/auth/landing_screen.dart';
export 'common/auth/login_screen.dart';
export 'common/auth/multi_step_register_screen.dart';
export 'common/dashboard_screen.dart';
export 'common/profile_screen.dart';
export 'common/profile_edit_screen.dart';
export 'common/donation_detail_screen.dart';
export 'common/notifications_screen.dart';

// Restaurant screens
export 'restaurant/home_screen.dart';
export 'restaurant/donations_screen.dart';
export 'restaurant/add_donation_screen.dart';
export 'restaurant/pickup_requests_screen.dart';

// Organization screens
export 'organization/home_screen.dart';
export 'organization/available_donations_screen.dart';
export 'organization/my_pickups_screen.dart';
