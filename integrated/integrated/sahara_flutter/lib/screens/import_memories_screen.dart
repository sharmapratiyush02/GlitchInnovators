// lib/screens/import_memories_screen.dart
// ─────────────────────────────────────────────────────────────
// Sahara — Import Memories Screen
// FULLY WEB-SAFE: never accesses file.path, catches all errors
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class ImportMemoriesScreen extends StatefulWidget {
  final VoidCallback? onImportSuccess;
  final VoidCallback? onSkip;

  const ImportMemoriesScreen({
    super.key,
    this.onImportSuccess,
    this.onSkip,
  });

  @override
  State<ImportMemoriesScreen> createState() => _ImportMemoriesScreenState();
}

class _ImportMemoriesScreenState extends State<ImportMemoriesScreen> {
  static const _baseUrl = 'http://localhost:5000';

  String?    _fileName;
  Uint8List? _fileBytes;

  bool    _isUploading  = false;
  bool    _isReady      = false;
  String? _errorMessage;
  String? _successMessage;

  // ── File picker ─────────────────────────────────────────────

  Future<void> _pickFile() async {
    setState(() {
      _errorMessage   = null;
      _successMessage = null;
      _isReady        = false;
      _fileBytes      = null;
      _fileName       = null;
    });

    FilePickerResult? result;

    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        withData: true,      // ← always load bytes, no path access ever
        withReadStream: false,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'File picker could not open. Please try again.');
      }
      return;
    }

    if (result == null || result.files.isEmpty) return;

    Uint8List? bytes;
    String?    name;

    try {
      final f = result.files.first;
      // NEVER access f.path — it throws on web
      bytes = f.bytes;
      name  = f.name;
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not read file. Please try again.');
      }
      return;
    }

    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        setState(() => _errorMessage = 'File appears empty. Please choose a valid _chat.txt file.');
      }
      return;
    }

    if (mounted) {
      setState(() {
        _fileName  = name ?? 'chat.txt';
        _fileBytes = bytes;
        _isReady   = true;
      });
    }
  }

  // ── Upload to backend ────────────────────────────────────────

  Future<void> _uploadFile() async {
    if (!_isReady || _fileBytes == null) return;

    setState(() {
      _isUploading  = true;
      _errorMessage = null;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/import'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'chat_file',
          _fileBytes!,
          filename: _fileName ?? 'chat.txt',
        ),
      );

      final streamed  = await request.send().timeout(const Duration(seconds: 90));
      final response  = await http.Response.fromStream(streamed);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data  = jsonDecode(response.body);
        final count = data['message_count'] ?? data['indexed'] ?? 0;
        setState(() {
          _successMessage = '✓ $count memories indexed successfully!';
        });
        await Future.delayed(const Duration(milliseconds: 1200));
        widget.onImportSuccess?.call();
      } else {
        String errMsg = 'Upload failed (${response.statusCode})';
        try {
          final body = jsonDecode(response.body);
          errMsg = body['error'] ?? errMsg;
        } catch (_) {}
        setState(() => _errorMessage = errMsg);
      }
    } catch (e) {
      if (!mounted) return;
      String msg = e.toString();
      if (msg.contains('SocketException') ||
          msg.contains('Connection refused') ||
          msg.contains('XMLHttpRequest') ||
          msg.contains('Failed host lookup')) {
        msg = 'Cannot reach backend.\nMake sure you ran:  python app.py';
      } else if (msg.contains('TimeoutException')) {
        msg = 'Timed out. The file may be too large or backend is busy.';
      }
      setState(() => _errorMessage = msg);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ─── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6CC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Traffic light dots
              Row(children: [
                _dot(const Color(0xFFFF5F57)),
                const SizedBox(width: 6),
                _dot(const Color(0xFFFFBD2E)),
                const SizedBox(width: 6),
                _dot(const Color(0xFFE6C84A)),
              ]),

              const SizedBox(height: 28),

              const Text(
                'Import\nMemories',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3D1F0A),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Export your WhatsApp chat with your loved one and import it here.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8B6E4E),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),
              _privacyBadge(),
              const SizedBox(height: 16),
              _howToExport(),
              const SizedBox(height: 16),
              _dropZone(),
              const SizedBox(height: 12),

              if (_errorMessage != null)   _errorBanner(_errorMessage!),
              if (_successMessage != null) _successBanner(_successMessage!),

              const Spacer(),
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Small widgets ────────────────────────────────────────────

  Widget _dot(Color color) => Container(
        width: 12, height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _privacyBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFD6E8D0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          const Icon(Icons.lock_outline, size: 16, color: Color(0xFF4A7C59)),
          const SizedBox(width: 8),
          Expanded(child: Text(
            '100% on-device processing. Your conversations are processed locally and never uploaded to any cloud server.',
            style: TextStyle(fontSize: 12, color: const Color(0xFF4A7C59).withOpacity(0.9), height: 1.4),
          )),
        ]),
      );

  Widget _howToExport() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEDD9B8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('How to export from WhatsApp:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF3D1F0A))),
          const SizedBox(height: 4),
          Text('Open chat → ⋮ Menu → More → Export Chat → Without Media',
              style: TextStyle(fontSize: 12, color: const Color(0xFF8B6E4E), height: 1.4)),
        ]),
      );

  Widget _dropZone() => GestureDetector(
        onTap: _isUploading ? null : _pickFile,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            color: _isReady ? const Color(0xFFFFF8EE) : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isReady ? const Color(0xFFB5652A) : const Color(0xFFD4A97A).withOpacity(0.4),
              width: _isReady ? 1.5 : 1,
            ),
          ),
          child: _isUploading
              ? _uploadingIndicator()
              : _isReady
                  ? _fileSelectedContent()
                  : _selectFileContent(),
        ),
      );

  Widget _selectFileContent() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.upload_file_rounded, size: 40, color: const Color(0xFFB5652A).withOpacity(0.8)),
          const SizedBox(height: 10),
          const Text('Tap to select _chat.txt',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF8B6E4E))),
        ],
      );

  Widget _fileSelectedContent() {
    final sizeKb = ((_fileBytes?.length ?? 0) / 1024).toStringAsFixed(1);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline_rounded, size: 36, color: Color(0xFFB5652A)),
        const SizedBox(height: 8),
        Text(
          _fileName ?? 'File selected',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF3D1F0A)),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text('$sizeKb KB · ready to process',
            style: TextStyle(fontSize: 12, color: const Color(0xFF8B6E4E).withOpacity(0.7))),
        const SizedBox(height: 6),
        TextButton(
          onPressed: _isUploading ? null : _pickFile,
          child: const Text('Choose different file',
              style: TextStyle(fontSize: 12, color: Color(0xFFB5652A))),
        ),
      ],
    );
  }

  Widget _uploadingIndicator() => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28, height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFB5652A)),
          ),
          SizedBox(height: 12),
          Text('Processing memories…', style: TextStyle(fontSize: 14, color: Color(0xFF8B6E4E))),
        ],
      );

  Widget _errorBanner(String msg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDE8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE07A5F).withOpacity(0.4)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFB5652A)),
          const SizedBox(width: 8),
          Expanded(child: Text(msg,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8B3A2A), height: 1.5))),
        ]),
      );

  Widget _successBanner(String msg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF4A7C59)),
          const SizedBox(width: 8),
          Expanded(child: Text(msg,
              style: const TextStyle(fontSize: 12, color: Color(0xFF2E6B3E), height: 1.4))),
        ]),
      );

  Widget _buildBottomButtons() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: (_isReady && !_isUploading) ? _uploadFile : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB5652A),
              disabledBackgroundColor: const Color(0xFFB5652A).withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isUploading
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("I'm ready",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: widget.onSkip,
            child: const Text('Skip for now',
                style: TextStyle(fontSize: 14, color: Color(0xFF8B6E4E))),
          ),
        ],
      );
}