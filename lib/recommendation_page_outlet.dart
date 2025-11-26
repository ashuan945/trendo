import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecommendationPageOutlet extends StatefulWidget {
  const RecommendationPageOutlet({super.key});

  @override
  State<RecommendationPageOutlet> createState() => _RecommendationPageOutletState();
}

class _RecommendationPageOutletState extends State<RecommendationPageOutlet> {
  bool isLoading = true;
  Map<String, dynamic>? insightData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchInsights();
  }

  Future<void> fetchInsights() async {
    try {
      final response = await http.get(
        Uri.parse('https://keugh3ttkl.execute-api.us-east-1.amazonaws.com/dev/insights?type=outlet'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          insightData = data['result'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load insights';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[600],
        elevation: 4,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          'Outlet Insights', 
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(errorMessage!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });
                          fetchInsights();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      isLoading = true;
                    });
                    await fetchInsights();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextCard(
                          title: 'Executive Summary',
                          icon: Icons.summarize,
                          color: Colors.deepPurple,
                          content: insightData?['executive_summary'] ?? '',
                        ),
                        _buildSectionCard(
                          title: 'Key Insights',
                          icon: Icons.lightbulb,
                          color: Colors.amber,
                          items: insightData?['key_insights'] ?? [],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          title: 'Trends & Patterns',
                          icon: Icons.trending_up,
                          color: Colors.green,
                          items: insightData?['trends_patterns'] ?? [],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          title: 'Stock & Inventory Insights',
                          icon: Icons.inventory_2,
                          color: Colors.blue,
                          items: insightData?['stock_inventory_insights'] ?? [],
                        ),
                        const SizedBox(height: 16),
                        _buildTextCard(
                          title: 'Business Impact',
                          icon: Icons.business_center,
                          color: Colors.purple,
                          content: insightData?['business_impact'] ?? '',
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          title: 'Actionable Recommendations',
                          icon: Icons.check_circle,
                          color: Colors.teal,
                          items: insightData?['actionable_recommendations'] ?? [],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          title: 'Risk Factors',
                          icon: Icons.warning,
                          color: Colors.orange,
                          items: insightData?['risk_factors'] ?? [],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          title: 'Next Steps',
                          icon: Icons.next_plan,
                          color: Colors.indigo,
                          items: insightData?['next_steps'] ?? [],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<dynamic> items,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value.toString(),
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextCard({
    required String title,
    required IconData icon,
    required Color color,
    required String content,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}