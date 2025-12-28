class GlobalSettingsModel {
  final double bonusPercentR1;
  final double minPayout;
  final double bonusPercentR2; // For Creator
  final double pulsaBonusAmount; // Fixed amount for Pulsa
  final double minSaleForPulsa; // Threshold (5jt)
  final bool enableR1;
  final bool enableR2;

  // Specific Reward Toggles
  final bool enableR1Commission;
  final bool enableR1PulsaBonus;
  final bool enableR2Commission;
  final bool enableR2PulsaBonus;

  // Announcement
  final String latestInfo;
  final String webBaseUrl;

  // R2 Specific Thresholds (New)
  final double pulsaBonusAmountR2;

  final double minSaleForPulsaR2;

  final double minPulsaWithdrawal; // New

  // Bonus Limits
  final bool enableMaxPulsaBonusLimit;
  final int maxPulsaBonusCount;
  final bool enableMinCompletedSalesLimit;
  final int minCompletedSalesCount;
  final bool enableMinSalesLimit; // New

  // Withdrawal Schedule
  final List<int> allowedWithdrawalDays; // 1 = Mon, 7 = Sun

  GlobalSettingsModel({
    required this.bonusPercentR1,
    required this.minPayout,
    this.bonusPercentR2 = 10.0,
    this.pulsaBonusAmount = 50000.0, // Treated as R1
    this.minSaleForPulsa = 10000000.0, // Updated Default 10jt
    this.pulsaBonusAmountR2 = 50000.0,
    this.minSaleForPulsaR2 = 10000000.0, // Updated Default 10jt
    this.minPulsaWithdrawal = 20000.0, // Default 20k
    this.enableR1 = true,
    this.enableR2 = true,
    this.enableR1Commission = true,
    this.enableR1PulsaBonus = true,
    this.enableR2Commission = true,
    this.enableR2PulsaBonus = true,
    this.latestInfo = 'Batas klaim pulsa bulan ini: Tgl 25.',
    this.webBaseUrl = 'https://kbm-group-app.web.app',
    this.allowedWithdrawalDays = const [1, 2, 3, 4, 5, 6, 7],
    this.enableMaxPulsaBonusLimit = true, // Default enabled
    this.maxPulsaBonusCount = 1, // Default 1x
    this.enableMinCompletedSalesLimit = false,
    this.minCompletedSalesCount = 5,
    this.enableMinSalesLimit = true,
  });

  factory GlobalSettingsModel.fromMap(Map<String, dynamic> data) {
    return GlobalSettingsModel(
      bonusPercentR1: (data['bonus_percent_r1'] ?? 0).toDouble(),
      minPayout: (data['min_payout'] ?? 5000000).toDouble(),
      bonusPercentR2: (data['bonus_percent_r2'] ?? 10).toDouble(),
      pulsaBonusAmount: (data['pulsa_bonus_amount'] ?? 50000).toDouble(),
      minSaleForPulsa: (data['min_sale_for_pulsa'] ?? 10000000).toDouble(),
      enableR1: data['enable_r1'] ?? true,
      enableR2: data['enable_r2'] ?? true,
      enableR1Commission: data['enable_r1_commission'] ?? true,
      enableR1PulsaBonus: data['enable_r1_pulsa_bonus'] ?? true,
      enableR2Commission: data['enable_r2_commission'] ?? true,
      enableR2PulsaBonus: data['enable_r2_pulsa_bonus'] ?? true,
      pulsaBonusAmountR2: (data['pulsa_bonus_amount_r2'] ?? 50000).toDouble(),
      minSaleForPulsaR2: (data['min_sale_for_pulsa_r2'] ?? 5000000).toDouble(),
      minPulsaWithdrawal: (data['min_pulsa_withdrawal'] ?? 20000).toDouble(),
      latestInfo: data['latest_info'] ?? 'Batas klaim pulsa bulan ini: Tgl 25.',
      webBaseUrl: data['web_base_url'] ?? 'https://kbm-group-app.web.app',
      allowedWithdrawalDays: List<int>.from(
        data['allowed_withdrawal_days'] ?? [1, 2, 3, 4, 5, 6, 7],
      ),
      enableMaxPulsaBonusLimit:
          data['enable_max_pulsa_bonus_limit'] ?? true, // Default true
      maxPulsaBonusCount: data['max_pulsa_bonus_count'] ?? 1,
      enableMinCompletedSalesLimit:
          data['enable_min_completed_sales_limit'] ?? false,
      minCompletedSalesCount: data['min_completed_sales_count'] ?? 5,
      enableMinSalesLimit: data['enable_min_sales_limit'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bonus_percent_r1': bonusPercentR1,
      'min_payout': minPayout,
      'bonus_percent_r2': bonusPercentR2,
      'pulsa_bonus_amount': pulsaBonusAmount,
      'min_sale_for_pulsa': minSaleForPulsa,
      'enable_r1': enableR1,
      'enable_r2': enableR2,
      'enable_r1_commission': enableR1Commission,
      'enable_r1_pulsa_bonus': enableR1PulsaBonus,
      'enable_r2_commission': enableR2Commission,
      'enable_r2_pulsa_bonus': enableR2PulsaBonus,
      'pulsa_bonus_amount_r2': pulsaBonusAmountR2,
      'min_sale_for_pulsa_r2': minSaleForPulsaR2,
      'min_pulsa_withdrawal': minPulsaWithdrawal,
      'latest_info': latestInfo,
      'web_base_url': webBaseUrl,
      'allowed_withdrawal_days': allowedWithdrawalDays,
      'enable_max_pulsa_bonus_limit': enableMaxPulsaBonusLimit,
      'max_pulsa_bonus_count': maxPulsaBonusCount,
      'enable_min_completed_sales_limit': enableMinCompletedSalesLimit,
      'min_completed_sales_count': minCompletedSalesCount,
      'enable_min_sales_limit': enableMinSalesLimit,
    };
  }
}
