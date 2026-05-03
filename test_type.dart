void main() {
  Map<Object?, Object?> map = {'a': 1};
  print(map is Map<dynamic, dynamic>);
  var x = map as Map<dynamic, dynamic>;
  print(x);
}
