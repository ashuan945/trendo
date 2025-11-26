import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'product_detail_page.dart';
import 'product_data.dart';
// Import the new utility classes
import 'utils/stock_analyzer.dart';
import 'utils/ui_utils.dart';
import 'models/enums.dart';
import 'sample_products.dart';
import 'widget/draggable_chatbot.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedRiskLevel = 'Risk Level';
  String selectedSort = 'Sort';

  final List<String> riskLevels = ['Risk Level', 'Low', 'Medium', 'High'];
  final List<String> sortOptions = [
    'Sort',
    'Name A-Z',
    'Name Z-A',
    'Risk Level',
  ];

  // Sample product data

  List<ProductData> allProducts = sampleProducts;

  // --- Simplified using StockAnalyzer ---
  String get stockRiskSummary {
    List<String?> daysList = allProducts
        .map((p) => p.daysWithoutStock)
        .toList();
    Map<RiskLevel, int> summary = StockAnalyzer.generateRiskSummary(daysList);
    return StockAnalyzer.formatRiskSummary(summary);
  }

  List<String> get topSellingProducts {
    List<Map<String, dynamic>> productsWithUnits = allProducts.map((p) {
      int units = StockAnalyzer.extractUnitsFromForecast(p.forecast);
      return {"name": p.name, "units": units};
    }).toList();

    productsWithUnits.sort(
      (a, b) => (b["units"] as int).compareTo(a["units"] as int),
    );

    return productsWithUnits.take(3).map((e) => e["name"] as String).toList();
  }

  String get topSellingSummary {
    List<String> list = [];
    for (int i = 0; i < 3; i++) {
      if (i < topSellingProducts.length) {
        list.add("${i + 1}. ${topSellingProducts[i]}");
      } else {
        list.add("${i + 1}. —"); // placeholder
      }
    }
    return list.join("\n");
  }

  List<ProductData> get filteredProducts {
    List<ProductData> filtered = List.from(allProducts);

    // Filter by risk level using StockAnalyzer
    if (selectedRiskLevel != 'Risk Level') {
      filtered = filtered
          .where(
            (product) =>
                StockAnalyzer.calculateRiskLevel(
                  product.daysWithoutStock,
                ).toString() ==
                selectedRiskLevel,
          )
          .toList();
    }

    // Sort products
    if (selectedSort == 'Name A-Z') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    } else if (selectedSort == 'Name Z-A') {
      filtered.sort((a, b) => b.name.compareTo(a.name));
    } else if (selectedSort == 'Risk Level') {
      const riskOrder = {'High': 0, 'Medium': 1, 'Low': 2};
      filtered.sort((a, b) {
        String aRisk = StockAnalyzer.calculateRiskLevel(
          a.daysWithoutStock,
        ).toString();
        String bRisk = StockAnalyzer.calculateRiskLevel(
          b.daysWithoutStock,
        ).toString();
        return (riskOrder[aRisk] ?? 3).compareTo(riskOrder[bRisk] ?? 3);
      });
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.blue[600],
            elevation: 4,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            title: Text(
              'Dashboard',
              style: TextStyle(
                fontSize: UIUtils.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            padding: UIUtils.getResponsivePadding(context),
            child: Column(
              children: [
                _buildFilters(),
                const SizedBox(height: 16),
                _buildProductList(),
              ],
            ),
          ),
        ),
        DraggableChatbot(),
      ],
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterDropdown(
            value: selectedRiskLevel,
            items: riskLevels,
            onChanged: (value) => setState(() => selectedRiskLevel = value),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterDropdown(
            value: selectedSort,
            items: sortOptions,
            onChanged: (value) => setState(() => selectedSort = value),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: UIUtils.getCardBorderRadius(),
        color: Colors.white,
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: Container(),
        style: TextStyle(
          fontSize: UIUtils.getResponsiveFontSize(context, 13),
          color: Colors.grey[800],
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) onChanged(newValue);
        },
      ),
    );
  }

  Widget _buildProductList() {
    List<ProductData> products = filteredProducts;

    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: UIUtils.getCardBorderRadius(),
          boxShadow: UIUtils.getCardShadow(),
        ),
        child: Center(
          child: Text(
            'No products match the selected filters',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: UIUtils.getResponsiveFontSize(context, 16),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: UIUtils.getCardBorderRadius(),
        boxShadow: UIUtils.getCardShadow(),
      ),
      child: Column(
        children: products.asMap().entries.map((entry) {
          int index = entry.key;
          ProductData product = entry.value;

          // Use StockAnalyzer for analysis
          StockAnalysisResult analysis = StockAnalyzer.analyzeStock(
            product.daysWithoutStock,
            product.forecast,
          );

          return Column(
            children: [
              _buildProductItem(
                name: product.name,
                forecast: product.forecast,
                currentStock: product.currentStock,
                daysWithoutStock: product.daysWithoutStock,
                recommendation: product.recommendation,
                status: analysis.riskLevelString,
                statusColor: analysis.riskColor,
              ),
              if (index < products.length - 1) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductItem({
    required String name,
    required String forecast,
    String? currentStock,
    String? daysWithoutStock,
    String? recommendation,
    required String status,
    required Color statusColor,
  }) {
    return Padding(
      padding: UIUtils.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: UIUtils.getResponsiveFontSize(context, 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: UIUtils.getResponsiveFontSize(context, 12),
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Forecast: $forecast',
            style: TextStyle(
              fontSize: UIUtils.getResponsiveFontSize(context, 14),
              color: Colors.grey[700],
            ),
          ),
          if (currentStock != null && currentStock.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Current Stock: $currentStock',
              style: TextStyle(
                fontSize: UIUtils.getResponsiveFontSize(context, 14),
                color: Colors.grey[700],
              ),
            ),
          ],
          if (daysWithoutStock != null && daysWithoutStock.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Days until without Stock: $daysWithoutStock',
              style: TextStyle(
                fontSize: UIUtils.getResponsiveFontSize(context, 14),
                color: Colors.grey[700],
              ),
            ),
          ],
          if (recommendation != null && recommendation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: UIUtils.getResponsiveFontSize(context, 16),
                  color: Colors.orange[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    recommendation,
                    style: TextStyle(
                      fontSize: UIUtils.getResponsiveFontSize(context, 14),
                      color: Colors.orange[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Find the product data to pass to detail page
                ProductData productToPass = ProductData(
                  name: name,
                  forecast: forecast,
                  currentStock: currentStock,
                  daysWithoutStock: daysWithoutStock,
                  recommendation: recommendation,
                  stockStatus: status,
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductDetailPage(product: productToPass),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View Details',
                style: TextStyle(
                  fontSize: UIUtils.getResponsiveFontSize(context, 14),
                  color: Colors.blue[600],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
