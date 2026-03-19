import 'package:flutter/foundation.dart';

@immutable
class DashboardStatsModel {
  final int todayAuctionCount;
  final double todayTotalAmount;
  final int totalFishCount;
  final int totalBoatCount;
  final int totalCariCount;
  final int totalAuctionCount;
  final List<RecentAuctionItem> recentAuctions;

  const DashboardStatsModel({
    required this.todayAuctionCount,
    required this.todayTotalAmount,
    required this.totalFishCount,
    required this.totalBoatCount,
    required this.totalCariCount,
    required this.totalAuctionCount,
    required this.recentAuctions,
  });

  static DashboardStatsModel mock() => DashboardStatsModel(
        todayAuctionCount: 14,
        todayTotalAmount: 87540.50,
        totalFishCount: 23,
        totalBoatCount: 11,
        totalCariCount: 45,
        totalAuctionCount: 312,
        recentAuctions: [
          RecentAuctionItem(
            id: '1',
            fisNo: 'MZ-2026-0312',
            cariUnvan: 'Ahmet Balık Ltd.',
            amount: 12500.00,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          RecentAuctionItem(
            id: '2',
            fisNo: 'MZ-2026-0311',
            cariUnvan: 'Karadeniz Ticaret',
            amount: 8750.00,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          RecentAuctionItem(
            id: '3',
            fisNo: 'MZ-2026-0310',
            cariUnvan: 'Ege Balıkçılık A.Ş.',
            amount: 21000.00,
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          RecentAuctionItem(
            id: '4',
            fisNo: 'MZ-2026-0309',
            cariUnvan: 'Marmara Deniz Ürünleri',
            amount: 6300.00,
            createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          ),
          RecentAuctionItem(
            id: '5',
            fisNo: 'MZ-2026-0308',
            cariUnvan: 'İstanbul Balık Pazarı',
            amount: 15400.00,
            createdAt: DateTime.now().subtract(const Duration(hours: 7)),
          ),
        ],
      );
}

@immutable
class RecentAuctionItem {
  final String id;
  final String fisNo;
  final String cariUnvan;
  final double amount;
  final DateTime createdAt;

  const RecentAuctionItem({
    required this.id,
    required this.fisNo,
    required this.cariUnvan,
    required this.amount,
    required this.createdAt,
  });
}
