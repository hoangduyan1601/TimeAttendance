// Fake class to satisfy compiler for mobile/desktop
final window = Window();

class Window {
  void open(String url, String target) {}
  final location = Location();
}

class Location {
  void reload() {}
}
