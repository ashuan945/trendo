import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dashboard_page.dart';
import 'widget/draggable_chatbot.dart';

class SalesHistoryPage extends StatefulWidget {
  @override
  _SalesHistoryPageState createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage> {
  File? _selectedFile;
  String? _fileName;
  String? _s3Key;
  bool _isUploading = false;
  bool _isUploaded = false;

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
          _isUploading = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File selected: $_fileName'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 1),
          ),
        );

        await _uploadUsingPresignedUrl();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _uploadUsingPresignedUrl() async {
    try {
      if (_selectedFile == null || _fileName == null) {
        return;
      }
      setState(() {
        _isUploading = true;
      });

      // Read file and convert to base64
      final bytes = await _selectedFile!.readAsBytes();
      final base64File = base64Encode(bytes);

      // 1. Request presigned URL with file content
      final presignResponse = await http.post(
        Uri.parse(
          'https://w2qsl11vr9.execute-api.ap-southeast-1.amazonaws.com/dev',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'file': base64File, 'filename': _fileName}),
      );

      // Debug: Print response details
      print('Response Status: ${presignResponse.statusCode}');
      print('Response Headers: ${presignResponse.headers}');
      print('Response Body: ${presignResponse.body}');

      if (presignResponse.statusCode != 200) {
        throw Exception('Failed to get presigned URL: ${presignResponse.body}');
      }

      final presignData = jsonDecode(presignResponse.body);
      print('Parsed Data: $presignData');
      print('Available Keys: ${presignData.keys}');

      // If we reach here, the upload was successful
      setState(() {
        _isUploading = false;
        _isUploaded = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File uploaded successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isUploading = false;
        _isUploaded = false; // Reset upload status on error
      });
    }
  }

  void _generateForecast() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DashboardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text('Upload Sales Data'),
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Upload your sales history data to generate AI-powered forecasts and analytics',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // File Upload Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _isUploaded
                            ? Icons.check_circle
                            : Icons.cloud_upload_outlined,
                        size: 48,
                        color: _isUploaded
                            ? Colors.green[600]
                            : Colors.grey[600],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isUploaded
                            ? 'File Uploaded Successfully'
                            : 'Upload Excel or CSV File',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _isUploaded
                              ? Colors.green[700]
                              : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!_isUploaded)
                        Text(
                          'Supported formats: .xlsx, .xls, .csv',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 16),

                      if (!_isUploaded)
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _pickAndUploadFile,
                          icon: _isUploading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(Icons.upload),
                          label: Text(
                            _isUploading ? 'Uploading...' : 'Upload File',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      if (_isUploaded && _fileName != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.insert_drive_file,
                                color: Colors.green[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _fileName!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green[800],
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[600],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const Spacer(),

                Container(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _generateForecast,
                    icon: Icon(Icons.analytics, size: 24),
                    label: Text(
                      'Generate AI Forecast',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        DraggableChatbot(),
      ],
    );
  }
}
