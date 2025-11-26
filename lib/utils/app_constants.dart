// lib/utils/app_constants.dart
import 'package:flutter/material.dart';
import '../models/enums.dart';

class AppConstants {
  // Risk Level Thresholds
  static const int HIGH_RISK_THRESHOLD_DAYS = 4;
  static const int MEDIUM_RISK_THRESHOLD_DAYS = 10;
  
  // Color Mappings for Risk Levels
  static const Map<RiskLevel, Color> riskColors = {
    RiskLevel.high: Colors.red,
    RiskLevel.medium: Colors.orange,
    RiskLevel.low: Colors.green,
  };
  
  // Color Mappings for Stock Status
  static const Map<StockStatus, Color> stockStatusColors = {
    StockStatus.lowStock: Colors.red,
    StockStatus.moderateStock: Colors.orange,
    StockStatus.overstock: Colors.blue,
    StockStatus.optimal: Colors.green,
  };
  
  // Product Type to Icon Mapping
  static const Map<ProductType, IconData> productIcons = {
    ProductType.rice: Icons.grass,
    ProductType.egg: Icons.egg_outlined,
    ProductType.other: Icons.inventory,
  };
  
  // Status Icons
  static const Map<String, IconData> statusIcons = {
    'critical': Icons.error,
    'warning': Icons.warning,
    'normal': Icons.check_circle,
  };
  
  // Forecast Status Colors
  static const Map<String, Color> forecastStatusColors = {
    'critical': Colors.red,
    'warning': Colors.orange,
    'normal': Colors.green,
  };
  
  // UI Constants
  static const double defaultBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double defaultElevation = 4.0;
  
  // Responsive Design
  static const double referenceScreenWidth = 375.0;
  static const double minFontSize = 10.0;
  static const double maxFontSize = 24.0;
}