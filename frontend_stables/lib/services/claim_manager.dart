// lib/services/claim_manager.dart
class ClaimManager {
  /// The spot ID currently claimed by this user (or null if none)
  static String? claimedSpotId;

  /// Returns whether the user currently has a spot claimed
  static bool get hasClaim => claimedSpotId != null;

  /// Mark [spotId] as claimed by this user
  static void setClaim(String spotId) => claimedSpotId = spotId;

  /// Clear any existing claim
  static void clearClaim() => claimedSpotId = null;
}
