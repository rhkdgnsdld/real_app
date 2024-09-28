import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  String _name = '강광훈 선생님';

  String get name => _name;

  void updateName(String newName) {
    _name = newName;
    notifyListeners();
  }
}
