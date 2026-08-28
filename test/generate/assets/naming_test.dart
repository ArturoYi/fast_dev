import 'package:fast_dev/src/generate/assets/naming.dart';
import 'package:test/test.dart';

void main() {
  test('camelCase 与 snakeCase', () {
    expect(camelCase('images/logo'), 'imagesLogo');
    expect(snakeCase('images/logo'), 'images_logo');
    expect(camelCase('dart@test'), 'dartTest');
  });

  test('数字开头加 a 前缀', () {
    expect(convertToIdentifier('2logo'), 'a2logo');
  });

  test('重名先加扩展名', () {
    final names = uniqueDartIdentifiers(const [
      AssetNameInput(source: 'logo.png', isFile: true),
      AssetNameInput(source: 'logo.svg', isFile: true),
    ], style: camelCase);
    expect(names, ['logoPng', 'logoSvg']);
  });

  test('保留字加后缀', () {
    final names = uniqueDartIdentifiers(const [
      AssetNameInput(source: 'class', isFile: true),
    ], style: camelCase);
    expect(names.single, 'class_');
  });
}
