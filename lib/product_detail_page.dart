import 'package:flutter/material.dart';
import 'dart:ui' as dart_ui;
import 'product_data.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
// Import utility classes
import '../utils/stock_analyzer.dart' as stock;
import '../utils/ui_utils.dart' as ui;
import '../models/enums.dart';
import 'widget/draggable_chatbot.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'utils/ui_utils.dart';


class ProductDetailPage extends StatefulWidget {
  final ProductData product;

  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final PageController _pageController = PageController();
  int _currentChartPage = 0;

  Map<String, dynamic>? _chart1Insights; // Rice predictions
  Map<String, dynamic>? _chart2Insights; // Weekly sales
  Map<String, dynamic>? _chart3Insights; // Promotion analysis
  bool _isLoadingInsights = false;
  String? _insightsError;

  Object? _apiCurrentStock;
  Object? _apiDaysWithoutStock;
  Object? _apiForecast;
  bool _hasLoadedStockData = false;
  
  @override
  void initState() {
    super.initState();
    // Auto-load the QuickSight dashboard when page opens
    _fetchRiceSalesEmbedUrl();
    _fetchRiceWeeklySalesEmbedUrl();
    _fetchRicePromotionEmbedUrl();
    
    
    // Only load insights for Rice product
    if (widget.product.name.toLowerCase().contains('rice')) {
      _fetchInsights('predict_rice', 0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }


  // Generate weekday vs weekend sales data for PAST WEEK ONLY
  List<FlSpot> getWeekdaySalesData() {
    List<FlSpot> spots = [];
    DateTime startDate = DateTime.now().subtract(
      Duration(days: 6),
    ); // Last 7 days

    for (int i = 0; i < 7; i++) {
      DateTime day = startDate.add(Duration(days: i));
      bool isWeekend =
          day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

      double baseValue = 3500; // Base sales around 3500
      if (isWeekend) baseValue += 2000; // Weekend boost

      // Add some variation
      double variation = (i % 3) * 250;
      spots.add(FlSpot(i.toDouble(), baseValue + variation));
    }
    return spots;
  }

  // Generate promotion data for a specific period
  List<FlSpot> getPromotionPeriodData(bool withPromotion) {
    List<FlSpot> spots = [];
    for (int i = 0; i < 30; i++) {
      double baseValue = withPromotion ? 6500 : 3800; // Higher numbers
      double variation = (i % 5) * 250;
      double trend = withPromotion ? (i * 30) : (i * 10);
      spots.add(FlSpot(i.toDouble(), baseValue + variation + trend));
    }
    return spots;
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
              widget.product.name,
              style: TextStyle(
                fontSize: ui.UIUtils.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            padding: ui.UIUtils.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(context),
                const SizedBox(height: 20),
                _buildChartsSection(context),
                const SizedBox(height: 20),
                _buildCriticalInfoCard(context),
              ],
            ),
          ),
        ),
        DraggableChatbot(),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    bool isRiceProduct = widget.product.name.toLowerCase().contains('rice');

    String? currentStockDisplay;
    String? daysWithoutStockStr;
    
    if (isRiceProduct && _apiCurrentStock != null) {
      int stockValue = _apiCurrentStock as int;
      currentStockDisplay = '$stockValue units';
    } else {
      currentStockDisplay = widget.product.currentStock;
    }
    
    if (isRiceProduct && _apiDaysWithoutStock != null) {
      int daysValue = _apiDaysWithoutStock as int;
      daysWithoutStockStr = '$daysValue days';
    } else {
      daysWithoutStockStr = widget.product.daysWithoutStock;
    }
    
    String? forecast = isRiceProduct && _apiForecast != null 
        ? (_apiForecast as String?) 
        : widget.product.forecast;

    stock.StockAnalysisResult analysis = stock.StockAnalyzer.analyzeStock(
      daysWithoutStockStr,
      forecast ?? widget.product.forecast,
    );

    return Container(
      width: double.infinity,
      padding: ui.UIUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: ui.UIUtils.getCardBorderRadius(),
        boxShadow: ui.UIUtils.getCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status:',
                style: TextStyle(
                  fontSize: ui.UIUtils.getResponsiveFontSize(context, 18),
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              if (isRiceProduct && !_hasLoadedStockData && _isLoadingInsights)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: analysis.riskColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: analysis.riskColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  analysis.riskLevel == RiskLevel.high
                      ? Icons.error
                      : analysis.riskLevel == RiskLevel.medium
                      ? Icons.warning
                      : Icons.check_circle,
                  color: analysis.riskColor,
                  size: ui.UIUtils.getResponsiveFontSize(context, 16),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${analysis.stockStatusString} - ${analysis.riskLevel.displayName}',
                    style: TextStyle(
                      fontSize: ui.UIUtils.getResponsiveFontSize(context, 14),
                      color: analysis.riskColor,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (currentStockDisplay != null)
            Row(
              children: [
                Text(
                  'Current Stock: ',
                  style: TextStyle(
                    fontSize: ui.UIUtils.getResponsiveFontSize(context, 16),
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  currentStockDisplay,
                  style: TextStyle(
                    fontSize: ui.UIUtils.getResponsiveFontSize(context, 16),
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isRiceProduct && _hasLoadedStockData)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    ),
                  ),
              ],
            ),
          if (daysWithoutStockStr != null)
            Row(
              children: [
                Text(
                  'Days until without Stock: ',
                  style: TextStyle(
                    fontSize: ui.UIUtils.getResponsiveFontSize(context, 16),
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  daysWithoutStockStr,
                  style: TextStyle(
                    fontSize: ui.UIUtils.getResponsiveFontSize(context, 16),
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isRiceProduct && _hasLoadedStockData)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    ),
                  ),
              ],
            ),
          // Forecast with better layout
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Forecast (Next 3 Days):',
                style: TextStyle(
                  fontSize: ui.UIUtils.getResponsiveFontSize(context, 16),
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      forecast ?? widget.product.forecast,
                      style: TextStyle(
                        fontSize: ui.UIUtils.getResponsiveFontSize(context, 15),
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 640,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentChartPage = index;
              });
              
              // Only fetch insights for Rice product
              if (widget.product.name.toLowerCase().contains('rice')) {
                if (index == 0 && _chart1Insights == null) {
                  _fetchInsights('predict_rice', 0);
                } else if (index == 1 && _chart2Insights == null) {
                  _fetchInsights('rice_weekly_sales', 1);
                } else if (index == 2 && _chart3Insights == null) {
                  _fetchInsights('rice_promotion_analysis', 2);
                }
              }
            },
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildChart6MonthTrend(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildChartWeekdayWeekend(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildChartRicePromotion(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildPageIndicator(),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentChartPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentChartPage == index
                ? Colors.blue[600]
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // State for QuickSight embed URL (Rice Sales)
  String? _riceSalesEmbedUrl;
  bool _isLoadingRiceSales = false;
  String? _riceSalesError;
  WebViewController? _riceSalesController;
  DateTime? _riceSalesUrlFetchTime;

  // Fetch QuickSight embed URL
  Future<void> _fetchRiceSalesEmbedUrl() async {
    setState(() {
      _isLoadingRiceSales = true;
      _riceSalesError = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://keugh3ttkl.execute-api.us-east-1.amazonaws.com/dev/embed-url?type=predict_rice',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final embedUrl = data['embedUrl'];
        
        setState(() {
          _riceSalesEmbedUrl = embedUrl;
          _riceSalesUrlFetchTime = DateTime.now();
          _isLoadingRiceSales = false;
          
          // Create new WebView controller with the fresh URL
          _riceSalesController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(Colors.white)
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageStarted: (String url) {
                  print('QuickSight page started loading: $url');
                },
                onPageFinished: (String url) {
                  print('QuickSight page finished loading');
                },
                onWebResourceError: (WebResourceError error) {
                  print('QuickSight error: ${error.description}');
                  // If we get an auth error, the URL might be expired
                  if (error.description.contains('401') || 
                      error.description.contains('403') ||
                      error.description.contains('authorization')) {
                    setState(() {
                      _riceSalesError = 'Session expired. Please reload the dashboard.';
                      _riceSalesEmbedUrl = null;
                    });
                  }
                },
              ),
            )
            ..loadRequest(Uri.parse(embedUrl));
        });
      } else {
        final errorBody = response.body;
        setState(() {
          _riceSalesError = 'Failed to load dashboard (${response.statusCode}): $errorBody';
          _isLoadingRiceSales = false;
        });
      }
    } catch (e) {
      setState(() {
        _riceSalesError = 'Error loading dashboard: $e';
        _isLoadingRiceSales = false;
      });
    }
  }

  // Add this entire method after _fetchRiceSalesEmbedUrl()
  Future<void> _fetchInsights(String type, int chartIndex) async {
    setState(() {
      _isLoadingInsights = true;
      _insightsError = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://keugh3ttkl.execute-api.us-east-1.amazonaws.com/dev/insights?type=$type',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (chartIndex == 0) {
            _chart1Insights = data;
            
            // EXTRACT STOCK DATA FROM API RESPONSE
            if (!_hasLoadedStockData && data['result'] != null) {
              _extractStockData(data['result']);
              _hasLoadedStockData = true;
            }
          } else if (chartIndex == 1) {
            _chart2Insights = data;
          } else if (chartIndex == 2) {
            _chart3Insights = data;
          }
          _isLoadingInsights = false;
        });
      } else {
        setState(() {
          _insightsError = 'Failed to load insights (${response.statusCode})';
          _isLoadingInsights = false;
        });
      }
    } catch (e) {
      setState(() {
        _insightsError = 'Error loading insights: $e';
        _isLoadingInsights = false;
      });
    }
  }

  // ADD THIS NEW METHOD:
  void _extractStockData(Map<String, dynamic> result) {
    // Calculate total current stock from all outlets
    if (result['outlet_analysis'] != null) {
      List outlets = result['outlet_analysis'] as List;
      int totalStock = 0;
      for (var outlet in outlets) {
        totalStock += (outlet['current_stock'] as num?)?.toInt() ?? 0;
      }
      _apiCurrentStock = totalStock; // This will store as Object?
    }
    
    // Calculate days until without stock
    if (result['quantity_summary'] != null) {
      var qtySummary = result['quantity_summary'] as Map<String, dynamic>;
      double avgDailyPredicted = (qtySummary['avg_daily_predicted_quantity'] as num?)?.toDouble() ?? 1;
      
      if (_apiCurrentStock != null && avgDailyPredicted > 0) {
        int currentStockValue = (_apiCurrentStock as int);
        _apiDaysWithoutStock = (currentStockValue / avgDailyPredicted).ceil();
      }
    }
    
    // Set forecast from sales summary
    if (result['sales_summary'] != null && result['quantity_summary'] != null) {
      var salesSummary = result['sales_summary'] as Map<String, dynamic>;
      var quantitySummary = result['quantity_summary'] as Map<String, dynamic>;
      
      // Get predicted sales and quantity for next 3 days
      double forecastSales = (salesSummary['total_predicted_sales_rm'] as num?)?.toDouble() ?? 0;
      double forecastQuantity = (quantitySummary['total_predicted_quantity'] as num?)?.toDouble() ?? 0;
      
      // Format the forecast string
      String salesFormatted = 'RM${forecastSales.toStringAsFixed(2)}';
      String quantityFormatted = '${forecastQuantity.toStringAsFixed(0)} units';
      
      _apiForecast = '$salesFormatted / $quantityFormatted (Next 3 days)';
    }
  }
  
  // Check if QuickSight URL needs refresh (URLs typically expire after 5 minutes)
  bool _needsRiceSalesRefresh() {
    if (_riceSalesUrlFetchTime == null) return false;
    final timeSinceFetch = DateTime.now().difference(_riceSalesUrlFetchTime!);
    return timeSinceFetch.inMinutes >= 4; // Refresh before 5-minute expiry
  }

  Widget _buildChart6MonthTrend() {
  // Check if URL needs refresh
  if (_riceSalesEmbedUrl != null && _needsRiceSalesRefresh()) {
    // Silently refresh the URL in the background
    Future.microtask(() => _fetchRiceSalesEmbedUrl());
  }
  
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: UIUtils.getCardBorderRadius(),
      boxShadow: UIUtils.getCardShadow(),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.grass, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Rice Sales',
                  style: TextStyle(
                    fontSize: UIUtils.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            // Refresh button only
            if (_riceSalesEmbedUrl != null)
              IconButton(
                onPressed: _isLoadingRiceSales ? null : _fetchRiceSalesEmbedUrl,
                icon: Icon(
                  Icons.refresh,
                  size: 20,
                  color: _isLoadingRiceSales ? Colors.grey : Colors.blue[600],
                ),
                tooltip: 'Refresh Dashboard',
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        // QuickSight Dashboard Container - FIX: Use Expanded instead of fixed height
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildRiceSalesContent(),
          ),
        ),
      ],
    ),
  );
}

Widget _buildRiceSalesContent() {
  // Remove the initial state with "Load Dashboard" button
  // Start directly with loading state
  
  if (_isLoadingRiceSales) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading dashboard...',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'This may take a few seconds',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  if (_riceSalesError != null) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Dashboard',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _riceSalesError!,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchRiceSalesEmbedUrl,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  if (_riceSalesEmbedUrl != null && _riceSalesController != null) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: WebViewWidget(
        controller: _riceSalesController!,
      ),
    );
  }

  return const SizedBox.shrink();
}

// State for QuickSight embed URL (Weekly Rice Sales)
String? _riceWeeklySalesEmbedUrl;
bool _isLoadingRiceWeeklySales = false;
String? _riceWeeklySalesError;
WebViewController? _riceWeeklySalesController;
DateTime? _riceWeeklySalesUrlFetchTime;

// Fetch QuickSight embed URL for weekly sales
Future<void> _fetchRiceWeeklySalesEmbedUrl() async {
  setState(() {
    _isLoadingRiceWeeklySales = true;
    _riceWeeklySalesError = null;
  });

  try {
    final response = await http.get(
      Uri.parse(
        'https://keugh3ttkl.execute-api.us-east-1.amazonaws.com/dev/embed-url?type=rice_weekly_sales',
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final embedUrl = data['embedUrl'];

      setState(() {
        _riceWeeklySalesEmbedUrl = embedUrl;
        _riceWeeklySalesUrlFetchTime = DateTime.now();
        _isLoadingRiceWeeklySales = false;

        _riceWeeklySalesController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                print('QuickSight Weekly Sales started loading: $url');
              },
              onPageFinished: (String url) {
                print('QuickSight Weekly Sales finished loading');
              },
              onWebResourceError: (WebResourceError error) {
                print('QuickSight Weekly Sales error: ${error.description}');
                if (error.description.contains('401') ||
                    error.description.contains('403') ||
                    error.description.contains('authorization')) {
                  setState(() {
                    _riceWeeklySalesError = 'Session expired. Please reload the dashboard.';
                    _riceWeeklySalesEmbedUrl = null;
                  });
                }
              },
            ),
          )
          ..loadRequest(Uri.parse(embedUrl));
      });
    } else {
      setState(() {
        _riceWeeklySalesError =
            'Failed to load dashboard (${response.statusCode}): ${response.body}';
        _isLoadingRiceWeeklySales = false;
      });
    }
  } catch (e) {
    setState(() {
      _riceWeeklySalesError = 'Error loading dashboard: $e';
      _isLoadingRiceWeeklySales = false;
    });
  }
}

// Check if QuickSight URL needs refresh (before 5-min expiry)
bool _needsRiceWeeklySalesRefresh() {
  if (_riceWeeklySalesUrlFetchTime == null) return false;
  final timeSinceFetch = DateTime.now().difference(_riceWeeklySalesUrlFetchTime!);
  return timeSinceFetch.inMinutes >= 4;
}

Widget _buildChartWeekdayWeekend() {
  // Auto refresh if expired
  if (_riceWeeklySalesEmbedUrl != null && _needsRiceWeeklySalesRefresh()) {
    Future.microtask(() => _fetchRiceWeeklySalesEmbedUrl());
  }

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: ui.UIUtils.getCardBorderRadius(),
      boxShadow: ui.UIUtils.getCardShadow(),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.purple[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Past Week Sales Pattern',
                  style: TextStyle(
                    fontSize: ui.UIUtils.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            if (_riceWeeklySalesEmbedUrl != null)
              IconButton(
                onPressed: _isLoadingRiceWeeklySales ? null : _fetchRiceWeeklySalesEmbedUrl,
                icon: Icon(
                  Icons.refresh,
                  size: 20,
                  color: _isLoadingRiceWeeklySales ? Colors.grey : Colors.blue[600],
                ),
                tooltip: 'Refresh Dashboard',
              ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildRiceWeeklySalesContent(),
          ),
        ),
      ],
    ),
  );
}

Widget _buildRiceWeeklySalesContent() {
  if (_isLoadingRiceWeeklySales) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading dashboard...',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'This may take a few seconds',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  if (_riceWeeklySalesError != null) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Dashboard',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _riceWeeklySalesError!,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchRiceWeeklySalesEmbedUrl,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  if (_riceWeeklySalesEmbedUrl != null && _riceWeeklySalesController != null) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: WebViewWidget(
        controller: _riceWeeklySalesController!,
      ),
    );
  }

  return const SizedBox.shrink();
}

// // Fetch QuickSight embed URL for promotion analysis
// Future<void> _fetchRicePromotionEmbedUrl() async {
//   setState(() {
//     _isLoadingRicePromotion = true;
//     _ricePromotionError = null;
//   });

//   try {
//     final response = await http.get(
//       Uri.parse(
//         'https://keugh3ttkl.execute-api.us-east-1.amazonaws.com/dev/embed-url?type=rice_promotion_analysis',
//       ),
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       final embedUrl = data['embedUrl'];

//       setState(() {
//         _ricePromotionEmbedUrl = embedUrl;
//         _ricePromotionUrlFetchTime = DateTime.now();
//         _isLoadingRicePromotion = false;

//         _ricePromotionController = WebViewController()
//           ..setJavaScriptMode(JavaScriptMode.unrestricted)
//           ..setBackgroundColor(Colors.white)
//           ..setNavigationDelegate(
//             NavigationDelegate(
//               onPageStarted: (String url) {
//                 print('QuickSight Promotion Analysis started loading: $url');
//               },
//               onPageFinished: (String url) {
//                 print('QuickSight Promotion Analysis finished loading');
//               },
//               onWebResourceError: (WebResourceError error) {
//                 print('QuickSight Promotion Analysis error: ${error.description}');
//                 if (error.description.contains('401') ||
//                     error.description.contains('403') ||
//                     error.description.contains('authorization')) {
//                   setState(() {
//                     _ricePromotionError = 'Session expired. Please reload the dashboard.';
//                     _ricePromotionEmbedUrl = null;
//                   });
//                 }
//               },
//             ),
//           )
//           ..loadRequest(Uri.parse(embedUrl));
//       });
//     } else {
//       setState(() {
//         _ricePromotionError =
//             'Failed to load dashboard (${response.statusCode}): ${response.body}';
//         _isLoadingRicePromotion = false;
//       });
//     }
//   } catch (e) {
//     setState(() {
//       _ricePromotionError = 'Error loading dashboard: $e';
//       _isLoadingRicePromotion = false;
//     });
//   }
// }

// // Check if QuickSight URL needs refresh (before 5-min expiry)
// bool _needsRiceWeeklySalesRefresh() {
//   if (_riceWeeklySalesUrlFetchTime == null) return false;
//   final timeSinceFetch = DateTime.now().difference(_riceWeeklySalesUrlFetchTime!);
//   return timeSinceFetch.inMinutes >= 4;
// }

// bool _needsRicePromotionRefresh() {
//   if (_ricePromotionUrlFetchTime == null) return false;
//   final timeSinceFetch = DateTime.now().difference(_ricePromotionUrlFetchTime!);
//   return timeSinceFetch.inMinutes >= 4;
// }

// State for QuickSight embed URL (Promotion Analysis)
String? _ricePromotionEmbedUrl;
bool _isLoadingRicePromotion = false;
String? _ricePromotionError;
WebViewController? _ricePromotionController;
DateTime? _ricePromotionUrlFetchTime;

// Fetch QuickSight embed URL for weekly sales
Future<void> _fetchRicePromotionEmbedUrl() async {
  setState(() {
    _isLoadingRicePromotion = true;
    _ricePromotionError = null;
  });

  try {
    final response = await http.get(
      Uri.parse(
        'https://keugh3ttkl.execute-api.us-east-1.amazonaws.com/dev/embed-url?type=rice_promotion_analysis',
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final embedUrl = data['embedUrl'];

      setState(() {
        _ricePromotionEmbedUrl = embedUrl;
        _ricePromotionUrlFetchTime = DateTime.now();
        _isLoadingRicePromotion = false;

        _ricePromotionController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                print('QuickSight Rice Promotion started loading: $url');
              },
              onPageFinished: (String url) {
                print('QuickSight Rice Promotion finished loading');
              },
              onWebResourceError: (WebResourceError error) {
                print('QuickSight Rice Promotion error: ${error.description}');
                if (error.description.contains('401') ||
                    error.description.contains('403') ||
                    error.description.contains('authorization')) {
                  setState(() {
                    _ricePromotionError = 'Session expired. Please reload the dashboard.';
                    _ricePromotionEmbedUrl = null;
                  });
                }
              },
            ),
          )
          ..loadRequest(Uri.parse(embedUrl));
      });
    } else {
      setState(() {
        _ricePromotionError =
            'Failed to load dashboard (${response.statusCode}): ${response.body}';
        _isLoadingRicePromotion = false;
      });
    }
  } catch (e) {
    setState(() {
      _ricePromotionError = 'Error loading dashboard: $e';
      _isLoadingRicePromotion = false;
    });
  }
}
// Check if QuickSight URL needs refresh (before 5-min expiry)
bool _needsRicePromotionRefresh() {
  if (_ricePromotionUrlFetchTime == null) return false;
  final timeSinceFetch = DateTime.now().difference(_ricePromotionUrlFetchTime!);
  return timeSinceFetch.inMinutes >= 4;
}

Widget _buildChartRicePromotion() {
  // Auto refresh if expired
  if (_ricePromotionEmbedUrl != null && _needsRicePromotionRefresh()) {
    Future.microtask(() => _fetchRicePromotionEmbedUrl());
  }

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: ui.UIUtils.getCardBorderRadius(),
      boxShadow: ui.UIUtils.getCardShadow(),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.purple[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Promotion Impact Analysis',
                  style: TextStyle(
                    fontSize: ui.UIUtils.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            if (_ricePromotionEmbedUrl != null)
              IconButton(
                onPressed: _isLoadingRicePromotion ? null : _fetchRicePromotionEmbedUrl,
                icon: Icon(
                  Icons.refresh,
                  size: 20,
                  color: _isLoadingRicePromotion ? Colors.grey : Colors.blue[600],
                ),
                tooltip: 'Refresh Dashboard',
              ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildRicePromotionContent(),
          ),
        ),
      ],
    ),
  );
}

Widget _buildRicePromotionContent() {
  if (_isLoadingRicePromotion) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading dashboard...',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'This may take a few seconds',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  if (_ricePromotionError != null) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Dashboard',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _ricePromotionError!,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchRicePromotionEmbedUrl,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  if (_ricePromotionEmbedUrl != null && _ricePromotionController != null) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: WebViewWidget(
        controller: _ricePromotionController!,
      ),
    );
  }

  return const SizedBox.shrink();
}


  
  // Widget _buildChartPromotionComparison(BuildContext context) {
  //   // Generate continuous Rice Promotion data with color segments
  //   List<LineChartBarData> getLineChartBarData() {
  //     List<LineChartBarData> segments = [];
      
  //     // Helper to create spots for a range
  //     List<FlSpot> createSpots(int start, int end) {
  //       List<FlSpot> spots = [];
  //       double baseValue = 4000;
        
  //       for (int i = start; i <= end; i++) {
  //         double value = baseValue;
          
  //         // Define promotion periods
  //         bool isPromo1 = i >= 30 && i <= 50;
  //         bool isPromo2 = i >= 90 && i <= 110;
  //         bool isPromo3 = i >= 140 && i <= 160;
          
  //         // Base trend
  //         double trend = i * 4;
          
  //         // Weekly pattern
  //         int dayOfWeek = (i % 7);
  //         double weeklyPattern = (dayOfWeek == 5 || dayOfWeek == 6) ? 400 : -100;
          
  //         // Promotion boost - realistic increases
  //         double promoBoost = 0;
  //         if (isPromo1) {
  //           promoBoost = 1200 + ((i - 30) * 20);
  //         } else if (isPromo2) {
  //           promoBoost = 700 + ((i - 90) * 12);
  //         } else if (isPromo3) {
  //           promoBoost = 300 + ((i - 140) * 8);
  //         }
          
  //         // Random noise
  //         double noise = (math.Random(i).nextDouble() - 0.5) * 200;
          
  //         value = value + trend + weeklyPattern + promoBoost + noise;
  //         spots.add(FlSpot(i.toDouble(), value.clamp(3000, 9000)));
  //       }
        
  //       return spots;
  //     }
      
  //     // Normal period 1: 0-29
  //     segments.add(LineChartBarData(
  //       spots: createSpots(0, 30),
  //       isCurved: true,
  //       curveSmoothness: 0.4,
  //       color: Colors.blue[600],
  //       barWidth: 3,
  //       dotData: FlDotData(show: false),
  //       belowBarData: BarAreaData(
  //         show: true,
  //         color: Colors.blue[600]!.withOpacity(0.1),
  //       ),
  //     ));
      
  //     // Promo 1: 30-50 (Green)
  //     segments.add(LineChartBarData(
  //       spots: createSpots(30, 50),
  //       isCurved: true,
  //       curveSmoothness: 0.4,
  //       color: Colors.green[600],
  //       barWidth: 3,
  //       dotData: FlDotData(show: false),
  //       belowBarData: BarAreaData(
  //         show: true,
  //         color: Colors.green[600]!.withOpacity(0.1),
  //       ),
  //     ));
      
  //     // Normal period 2: 50-90
  //     segments.add(LineChartBarData(
  //       spots: createSpots(50, 90),
  //       isCurved: true,
  //       curveSmoothness: 0.4,
  //       color: Colors.blue[600],
  //       barWidth: 3,
  //       dotData: FlDotData(show: false),
  //       belowBarData: BarAreaData(
  //         show: true,
  //         color: Colors.blue[600]!.withOpacity(0.1),
  //       ),
  //     ));
      
  //     // Promo 2: 90-110 (Green)
  //     segments.add(LineChartBarData(
  //       spots: createSpots(90, 110),
  //       isCurved: true,
  //       curveSmoothness: 0.4,
  //       color: Colors.green[600],
  //       barWidth: 3,
  //       dotData: FlDotData(show: false),
  //       belowBarData: BarAreaData(
  //         show: true,
  //         color: Colors.green[600]!.withOpacity(0.1),
  //       ),
  //     ));
      
  //     // Normal period 3: 110-140
  //     segments.add(LineChartBarData(
  //       spots: createSpots(110, 140),
  //       isCurved: true,
  //       curveSmoothness: 0.4,
  //       color: Colors.blue[600],
  //       barWidth: 3,
  //       dotData: FlDotData(show: false),
  //       belowBarData: BarAreaData(
  //         show: true,
  //         color: Colors.blue[600]!.withOpacity(0.1),
  //       ),
  //     ));
      
  //     // Promo 3: 140-160 (Green)
  //     segments.add(LineChartBarData(
  //       spots: createSpots(140, 160),
  //       isCurved: true,
  //       curveSmoothness: 0.4,
  //       color: Colors.green[600],
  //       barWidth: 3,
  //       dotData: FlDotData(show: false),
  //       belowBarData: BarAreaData(
  //         show: true,
  //         color: Colors.green[600]!.withOpacity(0.1),
  //       ),
  //     ));
      
  //     // Normal period 4: 160-180
  //     segments.add(LineChartBarData(
  //       spots: createSpots(160, 180),
  //       isCurved: true,
  //       curveSmoothness: 0.4,
  //       color: Colors.blue[600],
  //       barWidth: 3,
  //       dotData: FlDotData(show: false),
  //       belowBarData: BarAreaData(
  //         show: true,
  //         color: Colors.blue[600]!.withOpacity(0.1),
  //       ),
  //     ));
      
  //     return segments;
  //   }

  //   List<LineChartBarData> lineSegments = getLineChartBarData();
    
  //   // Get all spots for tooltip handling
  //   List<FlSpot> getAllSpots() {
  //     List<FlSpot> allSpots = [];
  //     for (var segment in lineSegments) {
  //       allSpots.addAll(segment.spots);
  //     }
  //     return allSpots;
  //   }
    
  //   DateTime now = DateTime.now();

  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: ui.UIUtils.getCardBorderRadius(),
  //       boxShadow: ui.UIUtils.getCardShadow(),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           'Promotion Impact Analysis',
  //           style: TextStyle(
  //             fontSize: ui.UIUtils.getResponsiveFontSize(context, 16),
  //             fontWeight: FontWeight.bold,
  //             color: Colors.grey[800],
  //           ),
  //         ),
  //         const SizedBox(height: 4),
  //         Wrap(
  //           spacing: 12,
  //           runSpacing: 4,
  //           children: [
  //             Row(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Container(width: 16, height: 3, color: Colors.blue[600]),
  //                 const SizedBox(width: 4),
  //                 Text(
  //                   'Normal Sales',
  //                   style: TextStyle(fontSize: 10, color: Colors.grey[600]),
  //                 ),
  //               ],
  //             ),
  //             Row(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Container(
  //                   width: 16,
  //                   height: 3,
  //                   color: Colors.green[100]!.withOpacity(0.5),
  //                 ),
  //                 const SizedBox(width: 4),
  //                 Text(
  //                   'Promo Period',
  //                   style: TextStyle(fontSize: 10, color: Colors.grey[600]),
  //                 ),
  //               ],
  //             ),
  //             Row(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Container(width: 16, height: 3, color: Colors.green[600]),
  //                 const SizedBox(width: 4),
  //                 Text(
  //                   'Promo Sales',
  //                   style: TextStyle(fontSize: 10, color: Colors.grey[600]),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         Expanded(
  //           child: Stack(
  //             children: [
  //               // Sticky Y-axis
  //               Positioned(
  //                 left: 0,
  //                 top: 0,
  //                 bottom: 30,
  //                 width: 50,
  //                 child: Container(
  //                   color: Colors.white,
  //                   child: CustomPaint(
  //                     painter: YAxisPainter(
  //                       minY: 2500,
  //                       maxY: 9000,
  //                       interval: 1000,
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //               // Scrollable chart
  //               Padding(
  //                 padding: const EdgeInsets.only(left: 50),
  //                 child: SingleChildScrollView(
  //                   scrollDirection: Axis.horizontal,
  //                   reverse: true,
  //                   child: Container(
  //                     width: MediaQuery.of(context).size.width * 3.2,
  //                     padding: const EdgeInsets.only(top: 10, bottom: 30, right: 40, left: 20),
  //                     child: Stack(
  //                       children: [
  //                         // Promotion period highlights with labels
  //                         Positioned.fill(
  //                           child: CustomPaint(
  //                             painter: PromotionHighlightPainter(
  //                               minX: -5,
  //                               maxX: 185,
  //                               chartWidth: MediaQuery.of(context).size.width * 3.2 - 60,
  //                               promotionPeriods: [
  //                                 {'start': 30.0, 'end': 50.0, 'label': 'B1F1'},
  //                                 {'start': 90.0, 'end': 110.0, 'label': 'Flash'},
  //                                 {'start': 140.0, 'end': 160.0, 'label': '20%'},
  //                               ],
  //                             ),
  //                           ),
  //                         ),
  //                         // Line chart
  //                         LineChart(
  //                           LineChartData(
  //                             minX: -5,
  //                             maxX: 185,
  //                             lineTouchData: LineTouchData(
  //                               enabled: true,
  //                               touchTooltipData: LineTouchTooltipData(
  //                                 tooltipBgColor: Colors.black87,
  //                                 tooltipRoundedRadius: 8,
  //                                 tooltipPadding: EdgeInsets.all(8),
  //                                 getTooltipItems: (List<LineBarSpot> touchedSpots) {
  //                                   return touchedSpots.map((spot) {
  //                                     if (spot.x < 0 || spot.x > 180) return null;
                                      
  //                                     DateTime date = now.subtract(
  //                                       Duration(days: 180 - spot.x.toInt()),
  //                                     );
  //                                     String dateStr = DateFormat('MMM d').format(date);
                                      
  //                                     return LineTooltipItem(
  //                                       '$dateStr\nRM${(spot.y).toStringAsFixed(0)}',
  //                                       TextStyle(
  //                                         color: Colors.white,
  //                                         fontWeight: FontWeight.bold,
  //                                         fontSize: 11,
  //                                       ),
  //                                     );
  //                                   }).toList();
  //                                 },
  //                               ),
  //                             ),
  //                             gridData: FlGridData(
  //                               show: true,
  //                               drawVerticalLine: false,
  //                               horizontalInterval: 1000,
  //                               getDrawingHorizontalLine: (value) {
  //                                 return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
  //                               },
  //                             ),
  //                             titlesData: FlTitlesData(
  //                               leftTitles: AxisTitles(
  //                                 sideTitles: SideTitles(showTitles: false),
  //                               ),
  //                               rightTitles: AxisTitles(
  //                                 sideTitles: SideTitles(showTitles: false),
  //                               ),
  //                               topTitles: AxisTitles(
  //                                 sideTitles: SideTitles(showTitles: false),
  //                               ),
  //                               bottomTitles: AxisTitles(
  //                                 sideTitles: SideTitles(
  //                                   showTitles: true,
  //                                   interval: 1,
  //                                   getTitlesWidget: (value, meta) {
  //                                     if (value < 0 || value > 180) return const SizedBox();

  //                                     DateTime date = now.subtract(
  //                                       Duration(days: 180 - value.toInt()),
  //                                     );

  //                                     // Show month labels
  //                                     if (value % 30 == 0 || value == 0) {
  //                                       return Padding(
  //                                         padding: const EdgeInsets.only(top: 8, left: 5),
  //                                         child: Text(
  //                                           DateFormat('MMM').format(date),
  //                                           style: TextStyle(
  //                                             fontSize: 10,
  //                                             color: Colors.grey[600],
  //                                             fontWeight: FontWeight.w500,
  //                                           ),
  //                                         ),
  //                                       );
  //                                     }
                                      
  //                                     return const SizedBox();
  //                                   },
  //                                 ),
  //                               ),
  //                             ),
  //                             borderData: FlBorderData(
  //                               show: true,
  //                               border: Border(
  //                                 bottom: BorderSide(color: Colors.grey[300]!, width: 1),
  //                                 left: BorderSide(color: Colors.grey[300]!, width: 1),
  //                               ),
  //                             ),
  //                             minY: 2500,
  //                             maxY: 9000,
  //                             lineBarsData: lineSegments,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildCriticalInfoCard(BuildContext context) {
    // Check if this is Rice product - only Rice gets dynamic insights
    bool isRiceProduct = widget.product.name.toLowerCase().contains('rice');
    
    if (isRiceProduct) {
      // Rice product - show dynamic insights based on chart
      return _buildDynamicInsightsCard(context);
    } else {
      // Other products - show original hardcoded recommendation
      return _buildOriginalRecommendationCard(context);
    }
  }

  // New method for Rice - dynamic insights
  Widget _buildDynamicInsightsCard(BuildContext context) {
    // Get current insights based on page
    Map<String, dynamic>? currentInsights;
    String title = 'AI Insights';
    
    if (_currentChartPage == 0) {
      currentInsights = _chart1Insights;
      title = 'Rice Sales Predictions';
    } else if (_currentChartPage == 1) {
      currentInsights = _chart2Insights;
      title = 'Weekly Sales Analysis';
    } else if (_currentChartPage == 2) {
      currentInsights = _chart3Insights;
      title = 'Promotion Impact Analysis';
    }

    return Container(
      padding: ui.UIUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: ui.UIUtils.getCardBorderRadius(),
        border: Border.all(
          color: Colors.blue[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.blue[600],
                size: ui.UIUtils.getResponsiveFontSize(context, 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: ui.UIUtils.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Show loading state
          if (_isLoadingInsights)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                ),
              ),
            )
          
          // Show error state
          else if (_insightsError != null)
            Text(
              _insightsError!,
              style: TextStyle(
                fontSize: ui.UIUtils.getResponsiveFontSize(context, 14),
                color: Colors.red[700],
              ),
            )
          
          // Show insights content
          else if (currentInsights != null)
            _buildInsightsContent(context, currentInsights)
          
          // Show placeholder
          else
            Text(
              'Loading insights...',
              style: TextStyle(
                fontSize: ui.UIUtils.getResponsiveFontSize(context, 14),
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  // Original method for other products - unchanged behavior
  Widget _buildOriginalRecommendationCard(BuildContext context) {
    // Use StockAnalyzer to determine risk level
    stock.StockAnalysisResult analysis = stock.StockAnalyzer.analyzeStock(
      widget.product.daysWithoutStock,
      widget.product.forecast,
    );

    // Show if there's a recommendation OR if it's critical
    bool hasRecommendation =
        widget.product.recommendation != null &&
        widget.product.recommendation!.isNotEmpty;

    if (!hasRecommendation && !analysis.isCritical) return const SizedBox();

    return Container(
      padding: ui.UIUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: analysis.isCritical ? Colors.orange[50] : Colors.blue[50],
        borderRadius: ui.UIUtils.getCardBorderRadius(),
        border: Border.all(
          color: analysis.isCritical ? Colors.orange[200]! : Colors.blue[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                analysis.isCritical
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline,
                color: analysis.isCritical
                    ? Colors.orange[600]
                    : Colors.blue[600],
                size: ui.UIUtils.getResponsiveFontSize(context, 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  analysis.isCritical
                      ? 'Critical - Stockout Expected'
                      : 'Recommendation',
                  style: TextStyle(
                    fontSize: ui.UIUtils.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                    color: analysis.isCritical
                        ? Colors.orange[800]
                        : Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
          if (analysis.isCritical) ...[
            const SizedBox(height: 12),
            Text(
              'Product needed soon',
              style: TextStyle(
                fontSize: ui.UIUtils.getResponsiveFontSize(context, 14),
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (hasRecommendation) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: analysis.isCritical
                      ? Colors.orange[600]
                      : Colors.blue[600],
                  size: ui.UIUtils.getResponsiveFontSize(context, 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.product.recommendation!,
                    style: TextStyle(
                      fontSize: ui.UIUtils.getResponsiveFontSize(context, 14),
                      color: analysis.isCritical
                          ? Colors.orange[700]
                          : Colors.blue[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightsContent(BuildContext context, Map<String, dynamic> insights) {
    final result = insights['result'] as Map<String, dynamic>?;
    if (result == null) return const SizedBox();

    // Route to appropriate renderer based on current chart page
    if (_currentChartPage == 0) {
      return _buildChart1Content(context, result); // Rice Predictions
    } else if (_currentChartPage == 1) {
      return _buildChart2Content(context, result); // Weekly Sales
    } else if (_currentChartPage == 2) {
      return _buildChart3Content(context, result); // Promotion Analysis
    }
    
    return const SizedBox();
  }

  // Chart 1: Rice Predictions Content
  Widget _buildChart1Content(BuildContext context, Map<String, dynamic> result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Analysis Period
        if (result['analysis_period'] != null) ...[
          const SizedBox(height: 12),
          _buildSectionTitle('Analysis Period', context),
          const SizedBox(height: 6),
          ..._buildMapContent(result['analysis_period'] as Map<String, dynamic>, context),
        ],
        
        // Sales Summary
        if (result['sales_summary'] != null) ...[
          const SizedBox(height: 12),
          _buildSectionTitle('Sales Summary', context),
          const SizedBox(height: 6),
          ..._buildMapContent(result['sales_summary'] as Map<String, dynamic>, context),
        ],
        
        // Quantity Summary
        if (result['quantity_summary'] != null) ...[
          const SizedBox(height: 12),
          _buildSectionTitle('Quantity Summary', context),
          const SizedBox(height: 6),
          ..._buildMapContent(result['quantity_summary'] as Map<String, dynamic>, context),
        ],
        
        // Stock Recommendations Summary
        if (result['stock_recommendations'] != null) ...[
          const SizedBox(height: 12),
          _buildSectionTitle('Stock Recommendations', context),
          const SizedBox(height: 6),
          ..._buildMapContent(result['stock_recommendations'] as Map<String, dynamic>, context),
        ],
        
        // Key Insights
        if (result['key_insights'] != null) ...[
          const SizedBox(height: 12),
          _buildSectionTitle('Key Insights', context),
          const SizedBox(height: 6),
          ..._buildBulletList(result['key_insights'] as List, context),
        ],
        
        // Recommendations
        if (result['recommendations'] != null) ...[
          const SizedBox(height: 12),
          _buildSectionTitle('Next Actions', context),
          const SizedBox(height: 6),
          _buildRecommendationsContent(context, result['recommendations']),
        ],
      ],
    );
  }

  // Chart 2: Weekly Sales Content
  Widget _buildChart2Content(BuildContext context, Map<String, dynamic> result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Analysis Summary
        if (result['analysis_summary'] != null) ...[
          _buildSectionTitle('Analysis Summary', context),
          const SizedBox(height: 6),
          ..._buildMapContent(result['analysis_summary'] as Map<String, dynamic>, context),
        ],
        
        // Weekly Performance
        if (result['weekly_performance'] != null) ...[
          const SizedBox(height: 12),
          _buildSectionTitle('Weekly Performance', context),
          const SizedBox(height: 6),
          ..._buildNestedMapContent(result['weekly_performance'] as Map<String, dynamic>, context),
        ],
        
        // Performance Metrics
        if (result['performance_metrics'] != null) ...[
          const SizedBox(height: 12),
          _buildSectionTitle('Performance Metrics', context),
          const SizedBox(height: 6),
          ..._buildMapContent(result['performance_metrics'] as Map<String, dynamic>, context),
        ],
        
        // Outlet Analysis Summary
        if (result['outlet_analysis'] != null) ...[
          const SizedBox(height: 12),
          _buildSectionTitle('Outlet Analysis', context),
          const SizedBox(height: 6),
          _buildInfoRow('Total Outlets', '${(result['outlet_analysis'] as List).length}', context),
          const SizedBox(height: 6),
          ..._buildTopOutlets(result['outlet_analysis'] as List, context),
        ],
        
        // Key Insights
        if (result['key_insights'] != null) ...[
          const SizedBox(height: 12),
          _buildSectionTitle('Key Insights', context),
          const SizedBox(height: 6),
          ..._buildBulletList(result['key_insights'] as List, context),
        ],
        
        // Recommendations
        if (result['recommendations'] != null) ...[
          const SizedBox(height: 12),
          _buildSectionTitle('Recommendations', context),
          const SizedBox(height: 6),
          _buildRecommendationsContent(context, result['recommendations']),
        ],
      ],
    );
  }

  // Chart 3: Promotion Analysis Content
  Widget _buildChart3Content(BuildContext context, Map<String, dynamic> result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Analysis Summary
        if (result['analysis_summary'] != null) ...[
          _buildSectionTitle('Analysis Summary', context),
          const SizedBox(height: 6),
          ..._buildMapContent(result['analysis_summary'] as Map<String, dynamic>, context),
        ],
        
        // Promotion Campaigns Summary
        if (result['promotion_campaigns'] != null) ...[
          const SizedBox(height: 12),
          _buildSectionTitle('Promotion Campaigns', context),
          const SizedBox(height: 6),
          _buildInfoRow('Total Campaigns', '${(result['promotion_campaigns'] as List).length}', context),
          const SizedBox(height: 6),
          ..._buildPromotionCampaigns(result['promotion_campaigns'] as List, context),
        ],
        
        // Outlet Performance Summary
        if (result['outlet_performance'] != null) ...[
          const SizedBox(height: 12),
          _buildSectionTitle('Outlet Performance', context),
          const SizedBox(height: 6),
          _buildInfoRow('Total Outlets', '${(result['outlet_performance'] as List).length}', context),
          const SizedBox(height: 6),
          ..._buildTopPerformingOutlets(result['outlet_performance'] as List, context),
        ],
        
        // Key Insights
        if (result['key_insights'] != null) ...[
          const SizedBox(height: 12),
          _buildSectionTitle('Key Insights', context),
          const SizedBox(height: 6),
          ..._buildBulletList(result['key_insights'] as List, context),
        ],
        
        // Recommendations
        if (result['recommendations'] != null) ...[
          const SizedBox(height: 12),
          _buildSectionTitle('Recommendations', context),
          const SizedBox(height: 6),
          if (result['recommendations'] is List)
            ..._buildBulletList(result['recommendations'] as List, context)
          else
            _buildRecommendationsContent(context, result['recommendations']),
        ],
      ],
    );
  }

  Widget _buildRecommendations(BuildContext context, dynamic recommendations) {
    List<Widget> widgets = [];

    if (recommendations is Map<String, dynamic>) {
      // Handle nested recommendations (like in chart 1 and 2)
      recommendations.forEach((key, value) {
        if (value is List) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatKey(key),
                    style: TextStyle(
                      fontSize: ui.UIUtils.getResponsiveFontSize(context, 12),
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...value.map((rec) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '•',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rec.toString(),
                            style: TextStyle(
                              fontSize: ui.UIUtils.getResponsiveFontSize(context, 12),
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          );
        }
      });
    } else if (recommendations is List) {
      // Handle simple list recommendations (like in chart 3)
      widgets.addAll(
        recommendations.map((rec) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.arrow_right,
                color: Colors.blue[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rec.toString(),
                  style: TextStyle(
                    fontSize: ui.UIUtils.getResponsiveFontSize(context, 13),
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  String _formatKey(String key) {
    // Convert snake_case to Title Case
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // Helper: Build section title with underline
  Widget _buildSectionTitle(String title, BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.blue[300]!, width: 1.5),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  // Helper: Build info row (label: value)
  Widget _buildInfoRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Build content from Map
  List<Widget> _buildMapContent(Map<String, dynamic> map, BuildContext context) {
    List<Widget> widgets = [];
    
    map.forEach((key, value) {
      String displayValue = _formatValue(key, value);
      
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  _formatKey(key),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      );
    });
    
    return widgets;
  }

  // Helper: Build nested map content (for weekly_performance)
  List<Widget> _buildNestedMapContent(Map<String, dynamic> map, BuildContext context) {
    List<Widget> widgets = [];
    
    map.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatKey(key),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                ..._buildMapContent(value, context).map((w) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: w,
                )),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 8),
            child: Text(
              '${_formatKey(key)}: ${_formatValue(key, value)}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
        );
      }
    });
    
    return widgets;
  }

  // Helper: Build bullet list
  List<Widget> _buildBulletList(List items, BuildContext context, {Color? color}) {
    return items.map((item) => Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color ?? Colors.blue[600],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.toString(),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }

  // Helper: Build recommendations (handles both Map and List)
  Widget _buildRecommendationsContent(BuildContext context, dynamic recommendations) {
    List<Widget> widgets = [];

    if (recommendations is Map<String, dynamic>) {
      recommendations.forEach((key, value) {
        if (value is List) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatKey(key),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  ..._buildBulletList(value, context),
                ],
              ),
            ),
          );
        }
      });
    } else if (recommendations is List) {
      widgets.addAll(_buildBulletList(recommendations, context));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  // Helper: Build top outlets (for chart 2)
  List<Widget> _buildTopOutlets(List outlets, BuildContext context) {
    // Sort by total_sales and take top 3
    var sortedOutlets = List.from(outlets);
    sortedOutlets.sort((a, b) => (b['total_sales'] ?? 0).compareTo(a['total_sales'] ?? 0));
    var topOutlets = sortedOutlets.take(3).toList();
    
    return topOutlets.asMap().entries.map((entry) {
      int index = entry.key;
      var outlet = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 8),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: index == 0 ? Colors.amber : index == 1 ? Colors.grey[400] : Colors.brown[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${outlet['outlet']} - RM${(outlet['total_sales'] ?? 0).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // Helper: Build promotion campaigns (for chart 3)
  List<Widget> _buildPromotionCampaigns(List campaigns, BuildContext context) {
    return campaigns.map((campaign) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              campaign['promotion_name'] ?? 'Unknown',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${campaign['start_date']} to ${campaign['end_date']} (${campaign['duration_days']} days)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (campaign['description'] != null)
              Text(
                campaign['description'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  // Helper: Build top performing outlets (for chart 3)
  List<Widget> _buildTopPerformingOutlets(List outlets, BuildContext context) {
    // Sort by promotion_lift_percentage and take top 3
    var sortedOutlets = List.from(outlets);
    sortedOutlets.sort((a, b) => (b['promotion_lift_percentage'] ?? 0).compareTo(a['promotion_lift_percentage'] ?? 0));
    var topOutlets = sortedOutlets.take(3).toList();
    
    return topOutlets.asMap().entries.map((entry) {
      int index = entry.key;
      var outlet = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 8),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: index == 0 ? Colors.amber : index == 1 ? Colors.grey[400] : Colors.brown[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${outlet['outlet']} - ${(outlet['promotion_lift_percentage'] ?? 0).toStringAsFixed(2)}% lift',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // Helper: Format value based on key
  String _formatValue(String key, dynamic value) {
    if (value is num) {
      String formatted;
      if (value is double && value % 1 != 0) {
        formatted = value.toStringAsFixed(2);
      } else {
        formatted = value.toString();
      }
      
      // Add RM prefix for monetary values
      if (key.toLowerCase().contains('sales') || 
          key.toLowerCase().contains('amount') ||
          key.toLowerCase().contains('rm')) {
        return 'RM$formatted';
      }
      
      // Add % suffix for percentages
      if (key.toLowerCase().contains('percent') || 
          key.toLowerCase().contains('rate') || 
          key.toLowerCase().contains('growth') ||
          key.toLowerCase().contains('lift')) {
        return '$formatted%';
      }
      
      return formatted;
    } else if (value is List) {
      return value.join(', ');
    }
    
    return value.toString();
  }
}

// Custom painter for dashed line in legend
class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + 5, size.height / 2),
        paint,
      );
      startX += 8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Add this YAxisPainter class at the bottom of your file (outside the widget class)
class YAxisPainter extends CustomPainter {
  final double minY;
  final double maxY;
  final double interval;

  YAxisPainter({
    required this.minY,
    required this.maxY,
    required this.interval,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: dart_ui.TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    // Draw left border
    canvas.drawLine(
      Offset(size.width - 1, 0),
      Offset(size.width - 1, size.height),
      paint,
    );

    // Draw Y-axis labels
    for (double value = minY; value <= maxY; value += interval) {
      final normalizedY = 1 - (value - minY) / (maxY - minY);
      final y = normalizedY * size.height;

      // Draw horizontal grid line indicator
      paint.color = Colors.grey[200]!;
      canvas.drawLine(
        Offset(size.width - 1, y),
        Offset(size.width + 5, y),
        paint,
      );

      // Draw label
      final textSpan = TextSpan(
        text: '${(value / 1000).toStringAsFixed(1)}k',
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey[600],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: dart_ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(size.width - textPainter.width - 8, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PromotionHighlightPainter extends CustomPainter {
  final double minX;
  final double maxX;
  final double chartWidth;
  final List<Map<String, dynamic>> promotionPeriods;

  PromotionHighlightPainter({
    required this.minX,
    required this.maxX,
    required this.chartWidth,
    required this.promotionPeriods,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final xRange = maxX - minX;

    for (var promo in promotionPeriods) {
      final start = promo['start'] as double;
      final end = promo['end'] as double;
      final label = promo['label'] as String;

      // Calculate positions
      final startX = ((start - minX) / xRange) * chartWidth;
      final endX = ((end - minX) / xRange) * chartWidth;

      // Draw light green rectangle
      final rect = Rect.fromLTWH(startX, 0, endX - startX, size.height);
      final paint = Paint()
        ..color = Colors.green[100]!.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, paint);

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.green[300]!.withOpacity(0.3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawRect(rect, borderPaint);

      // Draw label
      final textSpan = TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.green[700],
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: dart_ui.TextDirection.ltr,
      );
      textPainter.layout();
      
      final labelX = startX + (endX - startX) / 2 - textPainter.width / 2;
      textPainter.paint(canvas, Offset(labelX, 8));
    }
  }

  @override
  bool shouldRepaint(PromotionHighlightPainter oldDelegate) => false;
}