void main() {
  dynamic json = {'location': {'lat': 123.4}};
  print((json['location']?['lat'] ?? 0.0).toDouble());
}
