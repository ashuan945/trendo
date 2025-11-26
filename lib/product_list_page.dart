import 'package:flutter/material.dart';
import 'product_data.dart';
import 'product_detail_page.dart';
import 'product_card.dart';
// Import utility classes
import '../utils/stock_analyzer.dart' as stock;
import '../utils/ui_utils.dart' as ui;
import 'sample_products.dart';
import 'widget/draggable_chatbot.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({Key? key}) : super(key: key);

  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  // Sample product data - in real app this would come from a database
  List<ProductData> products = sampleProducts;

  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductData> get filteredProducts {
    if (searchQuery.isEmpty) {
      return products;
    }
    return products
        .where(
          (product) =>
              product.name.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
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
              'Product List',
              style: TextStyle(
                fontSize: ui.UIUtils.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: false,
          ),
          body: Column(
            children: [
              // Search Bar
              Container(
                padding: ui.UIUtils.getResponsivePadding(context),
                color: Colors.grey[50],
                child: TextField(
                  controller: _searchController,
                  decoration: ui.UIUtils.getInputDecoration(
                    labelText: 'Search products...',
                    prefixIcon: Icons.search,
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[600]),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),

              // Product Count
              if (filteredProducts.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.grey[100],
                  child: Text(
                    '${filteredProducts.length} product${filteredProducts.length != 1 ? 's' : ''} found',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: ui.UIUtils.getResponsiveFontSize(context, 14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // Product List
              Expanded(
                child: filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: ui.UIUtils.getResponsivePadding(context),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          return ProductCard(
                            product: filteredProducts[index],
                            parentContext: context,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        DraggableChatbot(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            searchQuery.isNotEmpty
                ? 'No products found for "$searchQuery"'
                : 'No products added yet',
            style: TextStyle(
              fontSize: ui.UIUtils.getResponsiveFontSize(context, 18),
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Add your first product to get started',
            style: TextStyle(
              fontSize: ui.UIUtils.getResponsiveFontSize(context, 14),
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
