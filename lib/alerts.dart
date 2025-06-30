import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Alerts extends StatelessWidget {
  const Alerts({super.key,});

  @override
  Widget build(BuildContext context) {

    final alertProvider = Provider.of<AlertsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        backgroundColor: const Color(0xFF000000),
        foregroundColor: Colors.white,
      ),

      body: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate([
              
              //Show Alert Messages
              ListTile(
                leading: const Icon(
                  Icons.notifications_active_outlined,
                  color: Color(0xFF2196F3),
                ),
                title: const Text('Show Alert Messages'),
                subtitle: const Text('Control whether the app shows brief alerts when you perform actions.'),
                trailing: Switch(
                  value: alertProvider.showAlerts,
                  onChanged: alertProvider.toggleAlerts,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

//Alert Provider
class AlertsProvider extends ChangeNotifier {
  
  bool _showAlerts = true;

  bool get showAlerts => _showAlerts;

  void toggleAlerts(bool value) async {
    _showAlerts = value;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('showAlerts', _showAlerts);
    notifyListeners();
  }
}