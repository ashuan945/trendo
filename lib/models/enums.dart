// lib/models/enums.dart

enum RiskLevel {
  high,
  medium,
  low;
  
  @override
  String toString() {
    switch (this) {
      case RiskLevel.high:
        return 'High';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.low:
        return 'Low';
    }
  }
  
  String get displayName {
    switch (this) {
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.medium:
        return 'Medium Risk';
      case RiskLevel.low:
        return 'Low Risk';
    }
  }
}

enum StockStatus {
  lowStock,
  moderateStock,
  overstock,
  optimal;
  
  @override
  String toString() {
    switch (this) {
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.moderateStock:
        return 'Moderate Stock';
      case StockStatus.overstock:
        return 'Overstock';
      case StockStatus.optimal:
        return 'Optimal';
    }
  }
}

enum ProductType {
  rice,
  egg,
  other;
  
  @override
  String toString() {
    switch (this) {
      case ProductType.rice:
        return 'Rice';
      case ProductType.egg:
        return 'Egg';
      case ProductType.other:
        return 'Other';
    }
  }
  
  static ProductType fromString(String productName) {
    switch (productName.toLowerCase()) {
      case 'rice':
        return ProductType.rice;
      case 'egg':
        return ProductType.egg;
      default:
        return ProductType.other;
    }
  }
}

enum ForecastStatus {
  critical,
  warning,
  normal;
  
  @override
  String toString() {
    switch (this) {
      case ForecastStatus.critical:
        return 'critical';
      case ForecastStatus.warning:
        return 'warning';
      case ForecastStatus.normal:
        return 'normal';
    }
  }
}