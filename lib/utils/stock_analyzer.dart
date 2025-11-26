// lib/utils/stock_analyzer.dart
import 'package:flutter/material.dart';
import '../models/enums.dart';
import 'app_constants.dart';

class StockAnalyzer {
  /// Calculate risk level based on days without stock
  static RiskLevel calculateRiskLevel(String? daysWithoutStock) {
    if (daysWithoutStock == null || daysWithoutStock.isEmpty) {
      return RiskLevel.low;
    }

    final match = RegExp(r'(\d+)').firstMatch(daysWithoutStock);
    if (match == null) return RiskLevel.low;

    int days = int.parse(match.group(1)!);

    if (days < AppConstants.HIGH_RISK_THRESHOLD_DAYS) {
      return RiskLevel.high;
    } else if (days <= AppConstants.MEDIUM_RISK_THRESHOLD_DAYS) {
      return RiskLevel.medium;
    }
    return RiskLevel.low;
  }

  /// Determine stock status based on days without stock
  static StockStatus determineStockStatus(String? daysWithoutStock) {
    if (daysWithoutStock == null || daysWithoutStock.isEmpty) {
      return StockStatus.overstock;
    }

    final match = RegExp(r'(\d+)').firstMatch(daysWithoutStock);
    if (match == null) return StockStatus.overstock;

    int days = int.parse(match.group(1)!);

    if (days < AppConstants.HIGH_RISK_THRESHOLD_DAYS) {
      return StockStatus.lowStock;
    } else if (days <= AppConstants.MEDIUM_RISK_THRESHOLD_DAYS) {
      return StockStatus.moderateStock;
    }
    return StockStatus.overstock;
  }

  /// Get color for risk level
  static Color getRiskColor(RiskLevel riskLevel) {
    return AppConstants.riskColors[riskLevel] ?? Colors.grey;
  }

  /// Get color for stock status
  static Color getStockStatusColor(StockStatus stockStatus) {
    return AppConstants.stockStatusColors[stockStatus] ?? Colors.grey;
  }

  /// Get product type from product name
  static ProductType getProductType(String productName) {
    return ProductType.fromString(productName);
  }

  /// Get icon for product type
  static IconData getProductIcon(String productName) {
    ProductType productType = getProductType(productName);
    return AppConstants.productIcons[productType] ?? Icons.inventory;
  }

  /// Parse forecast data to extract units
  static int extractUnitsFromForecast(String forecast) {
    final match = RegExp(r'(\d+)k?\s*units', caseSensitive: false)
        .firstMatch(forecast);
    
    if (match != null) {
      String numberStr = match.group(1)!;
      int baseNumber = int.tryParse(numberStr) ?? 0;
      
      // Check if it contains 'k' for thousands
      if (forecast.toLowerCase().contains('k')) {
        return baseNumber * 1000;
      }
      return baseNumber;
    }
    
    // Fallback: try to extract any number
    final fallbackMatch = RegExp(r'(\d+)').firstMatch(forecast);
    return fallbackMatch != null ? int.tryParse(fallbackMatch.group(1)!) ?? 0 : 0;
  }

  /// Parse forecast data to extract monetary value
  static double extractMoneyFromForecast(String forecast) {
    final match = RegExp(r'RM\s*(\d+(?:\.\d+)?)k?', caseSensitive: false)
        .firstMatch(forecast);
    
    if (match != null) {
      String numberStr = match.group(1)!;
      double baseNumber = double.tryParse(numberStr) ?? 0.0;
      
      // Check if it contains 'k' for thousands
      if (forecast.toLowerCase().contains('k')) {
        return baseNumber * 1000;
      }
      return baseNumber;
    }
    
    return 0.0;
  }

  /// Create a comprehensive stock analysis result
  static StockAnalysisResult analyzeStock(String? daysWithoutStock, String forecast) {
    RiskLevel riskLevel = calculateRiskLevel(daysWithoutStock);
    StockStatus stockStatus = determineStockStatus(daysWithoutStock);
    int forecastUnits = extractUnitsFromForecast(forecast);
    double forecastMoney = extractMoneyFromForecast(forecast);
    
    return StockAnalysisResult(
      riskLevel: riskLevel,
      stockStatus: stockStatus,
      riskColor: getRiskColor(riskLevel),
      statusColor: getStockStatusColor(stockStatus),
      forecastUnits: forecastUnits,
      forecastMoney: forecastMoney,
    );
  }

  /// Generate risk summary for dashboard
  static Map<RiskLevel, int> generateRiskSummary(List<String?> daysWithoutStockList) {
    Map<RiskLevel, int> summary = {
      RiskLevel.high: 0,
      RiskLevel.medium: 0,
      RiskLevel.low: 0,
    };

    for (String? days in daysWithoutStockList) {
      RiskLevel risk = calculateRiskLevel(days);
      summary[risk] = (summary[risk] ?? 0) + 1;
    }

    return summary;
  }

  /// Format risk summary for display
  static String formatRiskSummary(Map<RiskLevel, int> summary) {
    return '${summary[RiskLevel.high]} High\n'
           '${summary[RiskLevel.medium]} Medium\n'
           '${summary[RiskLevel.low]} Low';
  }

  /// Get status icon for forecast status
  static IconData getStatusIcon(String status) {
    return AppConstants.statusIcons[status] ?? Icons.help_outline;
  }

  /// Get color for forecast status
  static Color getStatusColor(String status) {
    return AppConstants.forecastStatusColors[status] ?? Colors.grey;
  }
}

/// Result class for comprehensive stock analysis
class StockAnalysisResult {
  final RiskLevel riskLevel;
  final StockStatus stockStatus;
  final Color riskColor;
  final Color statusColor;
  final int forecastUnits;
  final double forecastMoney;

  StockAnalysisResult({
    required this.riskLevel,
    required this.stockStatus,
    required this.riskColor,
    required this.statusColor,
    required this.forecastUnits,
    required this.forecastMoney,
  });

  /// Convenience getter for risk level string
  String get riskLevelString => riskLevel.toString();
  
  /// Convenience getter for stock status string
  String get stockStatusString => stockStatus.toString();
  
  /// Check if this is a critical stock situation
  bool get isCritical => riskLevel == RiskLevel.high;
  
  /// Check if stock needs attention
  bool get needsAttention => riskLevel != RiskLevel.low;
}