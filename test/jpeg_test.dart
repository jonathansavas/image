import 'dart:io';
import 'dart:math';
import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  var dir = Directory('test/res/jpg');
  var files = dir.listSync(recursive: true);

  group('JPEG', () {
    for (var f in files) {
      if (f is! File || !f.path.endsWith('.jpg')) {
        continue;
      }

      final name = f.path.split(RegExp(r'(/|\\)')).last;
      test('$name', () {
        List<int> bytes = (f as File).readAsBytesSync();
        expect(JpegDecoder().isValidFile(bytes), equals(true));

        final image = JpegDecoder().decodeImage(bytes);
        if (image == null) {
          throw ImageException('Unable to decode JPEG Image: $name.');
        }

        final outJpg = JpegEncoder().encodeImage(image);
        File('.dart_tool/out/jpg/${name}')
          ..createSync(recursive: true)
          ..writeAsBytesSync(outJpg);

        // Make sure we can read what we just wrote.
        final image2 = JpegDecoder().decodeImage(outJpg);
        if (image2 == null) {
          throw ImageException('Unable to re-decode JPEG Image: $name.');
        }

        expect(image.width, equals(image2.width));
        expect(image.height, equals(image2.height));
      });
    }

    for (var i = 1; i < 9; ++i) {
      test('exif/orientation_$i/landscape', () {
        final image = JpegDecoder().decodeImage(
            File('test/res/jpg/landscape_$i.jpg').readAsBytesSync());
        expect(image.exif.hasOrientation, equals(true));
        expect(image.exif.orientation, equals(i));
        File('.dart_tool/out/jpg/landscape_$i.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(PngEncoder().encodeImage(bakeOrientation(image)));
      });

      test('exif/orientation_$i/portrait', () {
        final image = JpegDecoder().decodeImage(
            File('test/res/jpg/portrait_$i.jpg').readAsBytesSync());
        expect(image.exif.hasOrientation, equals(true));
        expect(image.exif.orientation, equals(i));
        File('.dart_tool/out/jpg/portrait_$i.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(PngEncoder().encodeImage(bakeOrientation(image)));
      });
    }

    test('Jpeg hide in Image', () {
      var jpegHider = JpegHider(quality: 85);

      var ran = Random();
      ['landscape', 'portrait'].forEach((element) {
        for (var j = 1; j < 9; j++) {
          Image img = JpegDecoder().decodeImage(File('test/res/jpg/$element\_$j.jpg').readAsBytesSync());
          var randomMsg = String.fromCharCodes(
              List<int>.generate(256, (i) => ran.nextInt(127 - 34) + 34));

          List<int> withHidden = jpegHider.hideMessage(img, randomMsg);
          var found = jpegHider.findMessage(withHidden);

          expect(found, equals(randomMsg));
        }
      });
    });

    test('Jpeg hide in bytes', () {
      var jpegHider = JpegHider(quality: 100);

      var ran = Random();
      ['landscape', 'portrait'].forEach((element) {
        for (var j = 2; j < 3; j++) {
          List<int> bytes = File('test/res/jpg/$element\_$j.jpg').readAsBytesSync();
          var randomMsg = String.fromCharCodes(
              List<int>.generate(256, (i) => ran.nextInt(127 - 34) + 34));

          List<int> withHidden = jpegHider.hideMessage(bytes, randomMsg);

          File('test/res/jpg/$element\_$j\_withHidden.jpg').writeAsBytesSync(withHidden);
          //return;

          var found = jpegHider.findMessage(withHidden);

          expect(found, equals(randomMsg));
        }
      });
    });
  });
}
