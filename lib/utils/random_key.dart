import 'dart:math';

/// 生成随机主键（UUID v4格式）
/// 格式为: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
/// 其中y是8、9、A或B
String generateRandomPrimaryKey() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(256));

  // 设置版本号为4 (UUID v4)
  values[6] = (values[6] & 0x0F) | 0x40;

  // 设置变体为 RFC 4122 规范
  values[8] = (values[8] & 0x3F) | 0x80;

  // 转换为十六进制字符串
  final hex = values.map((v) => v.toRadixString(16).padLeft(2, '0')).join();

  // 插入分隔符
  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20, 32)}';
}

List<String> batchGenerateRandomPrimaryKeys(int count) {
  final random = Random.secure();
  final values = List<int>.generate(count * 16, (i) => random.nextInt(256));

  // 批量设置版本号为4 (UUID v4)
  for (var i = 0; i < count; i++) {
    values[i * 16 + 6] = (values[i * 16 + 6] & 0x0F) | 0x40;
  }

  // 批量设置变体为 RFC 4122 规范
  for (var i = 0; i < count; i++) {
    values[i * 16 + 8] = (values[i * 16 + 8] & 0x3F) | 0x80;
  }

  final hex = values
      .map((v) => v.toRadixString(16).padLeft(2, '0'))
      .join()
      .split('');

  return [
    for (var i = 0; i < count; i++)
      '${hex.sublist(i * 32, i * 32 + 8).join()}-'
          '${hex.sublist(i * 32 + 8, i * 32 + 12).join()}-'
          '${hex.sublist(i * 32 + 12, i * 32 + 16).join()}-'
          '${hex.sublist(i * 32 + 16, i * 32 + 20).join()}-'
          '${hex.sublist(i * 32 + 20, i * 32 + 32).join()}',
  ];
}
