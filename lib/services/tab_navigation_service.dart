import 'package:flutter/foundation.dart';

import '../config/feature_flags.dart';

class TabNavigationService extends ChangeNotifier {
  int currentTab = 0;

  void setTab(int index) {
    if (currentTab != index) {
      currentTab = index;
      notifyListeners();
    }
  }

  void openStore() {
    if (!kEnablePremiumStore) return;
    setTab(1);
  }

  int get recordingsTabIndex => kEnablePremiumStore ? 2 : 1;

  int get radioTabIndex => kEnablePremiumStore ? 4 : 3;

  void openRecordings() => setTab(recordingsTabIndex);
}
