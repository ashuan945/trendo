import 'package:flutter/material.dart';
import 'product_data.dart';
import 'product_detail_page.dart';
// Import utility classes
import '../utils/stock_analyzer.dart' as stock;
import '../utils/ui_utils.dart' as ui;

class ProductCard extends StatelessWidget {
  final ProductData product;
  final BuildContext parentContext; // Needed for navigation
  final bool showCriticalInfo; // optional, default false

  const ProductCard({
    Key? key,
    required this.product,
    required this.parentContext,
    this.showCriticalInfo = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use StockAnalyzer for comprehensive analysis
    stock.StockAnalysisResult analysis = stock.StockAnalyzer.analyzeStock(
      product.daysWithoutStock, 
      product.forecast
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          parentContext,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Container(
        margin: ui.UIUtils.getResponsiveMargin(context),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: ui.UIUtils.getCardBorderRadius(),
          boxShadow: ui.UIUtils.getCardShadow(),
        ),
        child: Padding(
          padding: ui.UIUtils.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      stock.StockAnalyzer.getProductIcon(product.name),
                      color: Colors.blue[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: ui.UIUtils.getResponsiveFontSize(context, 18),
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: analysis.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: analysis.statusColor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            analysis.stockStatusString,
                            style: TextStyle(
                              color: analysis.statusColor,
                              fontSize: ui.UIUtils.getResponsiveFontSize(context, 12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              // Product Details
              if (product.forecast.isNotEmpty)
                _buildDetailRow(
                  context,
                  Icons.assessment, 
                  'Forecast', 
                  product.forecast
                ),
              if (product.currentStock != null)
                _buildDetailRow(
                  context,
                  Icons.inventory, 
                  'Current Stock', 
                  product.currentStock!
                ),
              if (product.daysWithoutStock != null)
                _buildDetailRow(
                  context,
                  Icons.schedule, 
                  'Days until out of stock', 
                  product.daysWithoutStock!
                ),

              if (product.recommendation != null && product.recommendation!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline, 
                        color: Colors.orange[600], 
                        size: ui.UIUtils.getResponsiveFontSize(context, 16)
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          product.recommendation!,
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: ui.UIUtils.getResponsiveFontSize(context, 13),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ', 
            style: TextStyle(
              color: Colors.grey[700], 
              fontWeight: FontWeight.w500, 
              fontSize: ui.UIUtils.getResponsiveFontSize(context, 14)
            )
          ),
          Expanded(
            child: Text(
              value, 
              style: TextStyle(
                color: Colors.black87, 
                fontSize: ui.UIUtils.getResponsiveFontSize(context, 14)
              )
            )
          ),
        ],
      ),
    );
  }
}