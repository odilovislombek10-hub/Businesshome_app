import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../api/api_client.dart';

/// Himoyalangan faylni yuklab olib, tizim ko'rsatkichida ochadi.
///
/// Saytda bu `http.get(url, {responseType: 'blob'})` va `<a download>` orqali bo'ladi — ya'ni
/// fayl **auth sarlavhasi bilan** olinadi. Shuning uchun ilovada ham oddiy havola ochilmaydi:
/// avval `ApiClient` orqali baytlar olinadi, so'ng diskka yozilib ochiladi.
///
/// [saveToDownloads] `true` bo'lsa fayl ilovaning tashqi papkasiga saqlanadi (foydalanuvchi uni
/// fayl menejerida topa oladi), aks holda vaqtinchalik papkaga — faqat ko'rish uchun.
///
/// Xatolik bo'lsa `false` qaytaradi; chaqiruvchi foydalanuvchiga xabar ko'rsatadi.
Future<bool> downloadAndOpen(String url, String fileName, {bool saveToDownloads = false}) async {
  try {
    final bytes = await ApiClient.instance.downloadBytes(url);

    Directory directory;
    if (saveToDownloads) {
      directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    } else {
      directory = await getTemporaryDirectory();
    }

    final safeName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File('${directory.path}/$safeName');
    await file.writeAsBytes(bytes);

    final result = await OpenFilex.open(file.path);
    // Ochadigan ilova topilmasa ham fayl saqlangan — bu xato emas.
    return result.type == ResultType.done || result.type == ResultType.noAppToOpen;
  } catch (_) {
    return false;
  }
}
