// Fake class to satisfy compiler for mobile/desktop
class html {
  static var window = Window();
}

class Window {
  void open(String url, String target) {}
}
