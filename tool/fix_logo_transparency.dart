// Run: dart run tool/fix_logo_transparency.dart
// Makes black/near-black pixels transparent in logo2.png for proper mobile display
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final logoPath = 'assets/images/logo2.png';
  final file = File(logoPath);
  if (!file.existsSync()) {
    print('Error: $logoPath not found');
    exit(1);
  }

  final bytes = file.readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) {
    print('Error: Could not decode image');
    exit(1);
  }

  // Make black and near-black pixels (RGB < 100) transparent for mobile
  const threshold = 100;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      if (r < threshold && g < threshold && b < threshold) {
        image.setPixelRgba(x, y, r, g, b, 0);
      }
    }
  }

  final out = img.encodePng(image);

  file.writeAsBytesSync(out);
  print('Fixed transparency in $logoPath');
}
