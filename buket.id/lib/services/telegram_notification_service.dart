import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../models/order.dart';
import '../models/cart_item.dart';

class TelegramNotificationService {
  // ⚠️ PENTING: Isi dengan Bot Token Telegram Anda (dari BotFather)
  // Format: 123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
  static const String botToken = String.fromEnvironment('TELEGRAM_BOT_TOKEN');

  // ⚠️ PENTING: Chat ID Anda (ambil dari @getmyid_bot)
  // Format: 1234567890 (ANGKA, bukan username)
  static const String chatId = String.fromEnvironment('TELEGRAM_CHAT_ID');

  // URL API Telegram
  static const String telegramApiUrl = 'https://api.telegram.org/bot';

  /// Test Telegram credentials
  static Future<bool> testCredentials() async {
    try {
      if (botToken.isEmpty || chatId.isEmpty) {
        debugPrint('❌ Bot Token atau Chat ID kosong!');
        return false;
      }

      debugPrint('🧪 Testing Telegram credentials...');

      final url = Uri.parse('$telegramApiUrl$botToken/getMe');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['ok'] == true) {
          final botInfo = result['result'];
          debugPrint('✅ Bot credentials valid!');
          debugPrint('   Bot Name: ${botInfo['first_name']}');
          debugPrint('   Bot Username: @${botInfo['username']}');
          return true;
        } else {
          debugPrint('❌ Bot Token invalid: ${result['description']}');
          return false;
        }
      } else {
        debugPrint('❌ HTTP Error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Telegram request failed');
      return false;
    }
  }

  /// Kirim test message ke Telegram
  static Future<bool> sendTestMessage() async {
    try {
      final testMessage = '''🧪 <b>TEST MESSAGE</b>

Ini adalah pesan test untuk memverifikasi koneksi Telegram.

⏰ ${_formatDateTime(DateTime.now())}''';

      return await _sendTelegramMessage(testMessage);
    } catch (e) {
      debugPrint('Telegram request failed');
      return false;
    }
  }

  /// Kirim notifikasi pembayaran ke Telegram
  static Future<bool> sendPaymentNotification({
    required Order order,
    required List<CartItem> items,
    String? userName,
    String? userEmail,
  }) async {
    try {
      debugPrint('🚀 sendPaymentNotification called');
      debugPrint('   Order ID: ${order.id}');
      debugPrint('   Items count: ${items.length}');
      debugPrint('   User: $userName ($userEmail)');

      final message = _formatOrderMessage(
        order: order,
        items: items,
        userName: userName,
        userEmail: userEmail,
      );

      debugPrint('📝 Formatted message length: ${message.length}');
      debugPrint('📤 Calling _sendTelegramMessage...');

      final result = await _sendTelegramMessage(message);

      debugPrint('📊 Result: $result');
      return result;
    } catch (e) {
      debugPrint('Telegram request failed');
      debugPrint('   Error type: ${e.runtimeType}');
      return false;
    }
  }

  /// Format pesan order untuk Telegram
  static String _formatOrderMessage({
    required Order order,
    required List<CartItem> items,
    String? userName,
    String? userEmail,
  }) {
    final buffer = StringBuffer();

    // Header dengan styling premium
    buffer.writeln('🌸 PESANAN BUKET BARU 🌸');

    // Info Pelanggan dengan styling premium
    buffer.writeln('👤 <b>INFORMASI PELANGGAN</b>');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    if (userName != null && userName.isNotEmpty) {
      buffer.writeln('  📝 Nama: <b>$userName</b>');
    }
    if (userEmail != null && userEmail.isNotEmpty) {
      buffer.writeln('  📧 Email: <code>$userEmail</code>');
    }
    buffer.writeln(
        '  🆔 Nomor Pesanan: <code>#${order.id.substring(0, 8).toUpperCase()}</code>');
    buffer.writeln(
        '  ⏰ Waktu Pemesanan: <b>${_formatDateTime(order.createdAt)}</b>');
    buffer.writeln('');

    // Detail Pengiriman
    buffer.writeln('📦 <b>DETAIL PENGIRIMAN</b>');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(
        '  🔄 Status: ${_getStatusEmoji(order.status)} <b>${_getStatusLabel(order.status)}</b>');
    buffer.writeln('  📍 Alamat Tujuan:');
    buffer.writeln('     <i>${order.address}</i>');
    buffer.writeln('  💳 Metode Pembayaran: <b>${order.paymentMethod}</b>');
    buffer.writeln('');

    // Item Details dengan format yang lebih detail dan menarik
    buffer.writeln(
        '🛍️  <b>DAFTAR PRODUK PESANAN</b> (<code>${items.length} item</code>)');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');

    double subtotal = 0;
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final itemTotal = item.bouquet.price * item.quantity;
      subtotal += itemTotal;
      final num = i + 1;

      buffer.writeln('<b>$num️⃣  ${item.bouquet.name}</b>');
      buffer.writeln(
          '   💰 Harga: <code>Rp${item.bouquet.price.toStringAsFixed(0)}</code>/pcs');
      buffer.writeln('   📊 Jumlah: <b>${item.quantity}x</b>');
      buffer.writeln(
          '   🧮 Subtotal: <code>Rp${itemTotal.toStringAsFixed(0)}</code>');

      if (item.notes != null && item.notes!.isNotEmpty) {
        buffer.writeln('   📝 Catatan: <i>${item.notes}</i>');
      }

      if (item.greetingCard != null && item.greetingCard!.isNotEmpty) {
        buffer.writeln('   💌 Kartu Ucapan: <i>${item.greetingCard}</i>');
      }

      if (i < items.length - 1) {
        buffer.writeln('   ───────────────────────────────────────────');
        buffer.writeln('');
      }
    }
    buffer.writeln('');
    buffer.writeln('');

    // Ringkasan Biaya dengan detail lebih jelas
    buffer.writeln('💰 <b>RINGKASAN PEMBAYARAN</b>');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(
        '  Subtotal Produk     : <code>Rp${subtotal.toStringAsFixed(0)}</code>');

    final tax = order.totalPrice - subtotal;
    if (tax > 0) {
      buffer.writeln(
          '  Biaya Layanan/Pajak : <code>Rp${tax.toStringAsFixed(0)}</code>');
    }

    buffer.writeln('  ───────────────────────────────────────────');
    buffer.writeln(
        '  <b>💵 TOTAL PEMBAYARAN   : Rp${order.totalPrice.toStringAsFixed(0)}</b>');
    buffer.writeln('');

    return buffer.toString();
  }

  /// Kirim pesan ke Telegram dengan inline keyboard
  static Future<bool> _sendTelegramMessageWithKeyboard(
    String message,
    Map<String, dynamic> replyMarkup,
  ) async {
    try {
      if (botToken.isEmpty || chatId.isEmpty) {
        debugPrint('! ERROR: Bot Token atau Chat ID belum di-setup!');
        debugPrint(
            '📝 Setup guide: lib/services/telegram_notification_service.dart');
        return false;
      }

      final url = Uri.parse('$telegramApiUrl$botToken/sendMessage');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'chat_id': chatId,
              'text': message,
              'parse_mode': 'HTML',
              'reply_markup': replyMarkup,
            }),
          )
          .timeout(const Duration(seconds: 10));
      debugPrint('📨 Telegram response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final success = result['ok'] ?? false;
        if (success) {
          debugPrint('✅ Telegram notification with button sent successfully');
          return true;
        } else {
          debugPrint('❌ Telegram API returned ok=false');
          return false;
        }
      } else {
        debugPrint('❌ Telegram API error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Telegram request failed');
      return false;
    }
  }

  /// Kirim pesan ke Telegram via Bot API
  static Future<bool> _sendTelegramMessage(String message) async {
    try {
      // Validasi Bot Token dan Chat ID sudah di-setup
      if (botToken.isEmpty || chatId.isEmpty) {
        debugPrint('⚠️ ERROR: Bot Token atau Chat ID belum di-setup!');
        debugPrint(
            '📝 Setup guide: lib/services/telegram_notification_service.dart');
        return false;
      }

      final url = Uri.parse('$telegramApiUrl$botToken/sendMessage');
      debugPrint('📤 [_sendTelegramMessage] Starting request');
      debugPrint('📝 Message length: ${message.length}');

      final bodyMap = {
        'chat_id': chatId,
        'text': message,
        'parse_mode': 'HTML',
      };
      final bodyJson = jsonEncode(bodyMap);
      debugPrint('📦 Body length: ${bodyJson.length}');

      try {
        debugPrint('⏳ Sending HTTP POST request (timeout: 8s)...');
        final response = await http
            .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: bodyJson,
        )
            .timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            debugPrint('⏱️ [TIMEOUT] Telegram API timeout after 8 seconds');
            throw TimeoutException('Telegram API timeout');
          },
        );

        debugPrint('✅ [RESPONSE] Got response from server');
        debugPrint('📨 Status Code: ${response.statusCode}');

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          final success = result['ok'] ?? false;
          debugPrint('📊 API Response ok: $success');

          if (success) {
            debugPrint('✅ [SUCCESS] Telegram notification sent successfully');
            debugPrint('   Message ID: ${result['result']?['message_id']}');
            return true;
          } else {
            final errorCode = result['error_code'];
            debugPrint('❌ [API_ERROR] Telegram API returned ok=false');
            debugPrint('Telegram request failed');

            // Error message hints
            if (errorCode == 401) {
              debugPrint('   💡 Hint: Bot Token mungkin tidak valid');
            } else if (errorCode == 400) {
              debugPrint('   💡 Hint: Chat ID mungkin tidak valid');
            }
            return false;
          }
        } else {
          debugPrint(
              '❌ [HTTP_ERROR] Telegram API error: ${response.statusCode}');
          return false;
        }
      } on TimeoutException {
        debugPrint('Telegram request failed');
        debugPrint('   • Emulator mungkin tidak punya internet access');
        debugPrint('   • Atau server Telegram sedang lambat');
        debugPrint('   • Coba di device real atau aktifkan internet emulator');
        return false;
      } on SocketException {
        debugPrint('Telegram request failed');
        debugPrint('   • Check your internet connection');
        debugPrint('   • Verify firewall settings');
        return false;
      }
    } catch (e) {
      debugPrint('Telegram request failed');
      debugPrint('   Error type: ${e.runtimeType}');
      debugPrint('Telegram request failed');
      return false;
    }
  }

  /// Format tanggal ke format readable
  static String _formatDateTime(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day ${months[date.month - 1]} ${date.year} - $hour:$minute';
  }

  /// Kirim notifikasi status update dengan button inline keyboard
  static Future<bool> sendStatusUpdateNotificationWithButton({
    required String orderId,
    required String newStatus,
    required String address,
    required double totalPrice,
  }) async {
    try {
      final statusLabel = _getStatusLabel(newStatus);
      final statusEmoji = _getStatusEmoji(newStatus);

      final message = '''═══════════════════════════════
$statusEmoji STATUS PESANAN DIPERBARUI $statusEmoji
═══════════════════════════════

📦 Pesanan: #${orderId.substring(0, 8).toUpperCase()}

🔄 Status Baru: $statusEmoji $statusLabel

📍 Alamat Pengiriman:
$address

💰 Total: Rp${totalPrice.toStringAsFixed(0)}

---
⏰ Waktu Update: ${_formatDateTime(DateTime.now())}

═══════════════════════════════''';

      // Buat inline keyboard dengan button
      final replyMarkup = {
        'inline_keyboard': [
          [
            {
              'text': '✅ Konfirmasi Pengiriman',
              'url': 'buket://confirm-order/$orderId'
            }
          ],
          [
            {'text': '📱 Buka di App', 'url': 'buket://confirm-order/$orderId'}
          ]
        ]
      };

      return await _sendTelegramMessageWithKeyboard(message, replyMarkup);
    } catch (e) {
      debugPrint('Telegram request failed');
      return false;
    }
  }

  /// Kirim notifikasi status update (tanpa button)
  static Future<bool> sendStatusUpdateNotification({
    required String orderId,
    required String newStatus,
    required String address,
    required double totalPrice,
  }) async {
    try {
      final statusLabel = _getStatusLabel(newStatus);
      final statusEmoji = _getStatusEmoji(newStatus);

      final message = '''╔═══════════════════════════════════════╗
║  $statusEmoji UPDATE STATUS PESANAN $statusEmoji  ║
╚═══════════════════════════════════════╝

📦 <b>Pesanan:</b> <code>#${orderId.substring(0, 8).toUpperCase()}</code>

🔄 <b>Status Baru:</b> $statusEmoji <b>$statusLabel</b>

📍 <b>Alamat Pengiriman:</b>
<i>$address</i>

💰 <b>Total Pesanan:</b> <code>Rp${totalPrice.toStringAsFixed(0)}</code>

⏰ <b>Update:</b> ${_formatDateTime(DateTime.now())}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Pesanan sedang kami proses dengan baik
╚═══════════════════════════════════════╝''';

      return await _sendTelegramMessage(message);
    } catch (e) {
      debugPrint('Telegram request failed');
      return false;
    }
  }

  /// Get label untuk status
  static String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending - Menunggu Persetujuan';
      case 'diproses':
      case 'sedang diproses':
        return 'Sedang Diproses';
      case 'dikirim':
      case 'sedang dikirim':
        return 'Sedang Dikirim';
      case 'terkirim':
        return 'Sudah Terkirim';
      case 'selesai':
      case 'delivered':
        return 'Selesai / Diterima';
      case 'dibatalkan':
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  /// Emoji untuk status pesanan
  static String _getStatusEmoji(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '⏳';
      case 'diproses':
      case 'sedang diproses':
        return '⚙️';
      case 'dikirim':
      case 'terkirim':
      case 'sedang dikirim':
        return '🚚';
      case 'selesai':
      case 'delivered':
        return '✅';
      case 'dibatalkan':
      case 'cancelled':
        return '❌';
      default:
        return '📌';
    }
  }
}
