import 'package:flutter/material.dart';

class ProductData {
  final String name;
  final String forecast;
  final String? currentStock;
  final String? daysWithoutStock;
  final String? recommendation;
  final String stockStatus;

  ProductData({
    required this.name,
    required this.forecast,
    this.currentStock,
    this.daysWithoutStock,
    this.recommendation,
    required this.stockStatus,
  });
}
