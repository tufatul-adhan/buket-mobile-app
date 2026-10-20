/// Generate PNG icons dari SVG logo untuk berbagai ukuran
/// Run dengan: dart generate_icons.dart (dari project root)

import 'dart:io';

Future<void> main() async {
  stdout.write('🎀 Buket.id Icon Generator (Dart Standalone)\n');
  stdout.write('Note: Standalone Dart cannot directly render SVG.\n');
  stdout.write('Please use one of these alternatives:\n\n');

  stdout.write('1. **Flutter Launcher Icons Package (Recommended)**:\n');
  stdout.write('   - Add flutter_launcher_icons to pubspec.yaml\n');
  stdout.write('   - Run: flutter pub run flutter_launcher_icons\n\n');

  stdout.write('2. **Online Converter**:\n');
  stdout.write('   - Go to: https://convertio.co/svg-png/\n');
  stdout.write('   - Upload: assets/icons/bouquet_logo.svg\n');
  stdout.write('   - Convert to PNG at 5 resolutions:\n\n');

  final iconSizes = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  };

  for (var entry in iconSizes.entries) {
    stdout.write(
        '     - ${entry.value}x${entry.value} → android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png\n');
  }

  stdout.write('\n3. **Python Script with cairosvg**:\n');
  stdout.write('   - pip install cairosvg\n');
  stdout.write('   - python generate_icons.py\n\n');

  stdout.write('4. **Command-line with FFmpeg**:\n');
  stdout.write(
      '   - ffmpeg -i assets/icons/bouquet_logo.svg -vf scale=48:-1 android/app/src/main/res/mipmap-mdpi/ic_launcher.png\n');
  stdout.write('   - (repeat for each size)\n\n');

  stdout.write('For now, the splash screen with SVG logo is ready!\n');
  stdout.write(
      'You can customize launcher icons later using any of the above methods.\n');
}
