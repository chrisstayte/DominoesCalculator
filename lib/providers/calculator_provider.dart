import 'package:dominoes/enum/domino_pips.dart';
import 'package:flutter/foundation.dart';

class CalculatorProvider extends ChangeNotifier {
  final List<DominoPips> _selectedPips = [];

  List<DominoPips> get selectedPips => List.unmodifiable(_selectedPips);

  int total({required int freePointValue}) {
    return _selectedPips.fold(0, (sum, pip) {
      return sum + (pip == DominoPips.p0 ? freePointValue : pip.value);
    });
  }

  void addPip(DominoPips pip) {
    _selectedPips.add(pip);
    notifyListeners();
  }

  void removeLast() {
    if (_selectedPips.isNotEmpty) {
      _selectedPips.removeLast();
      notifyListeners();
    }
  }

  void clear() {
    if (_selectedPips.isNotEmpty) {
      _selectedPips.clear();
      notifyListeners();
    }
  }
}
