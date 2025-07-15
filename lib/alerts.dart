import 'package:flutter/material.dart';
//import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/*
class Alerts extends StatelessWidget {
  const Alerts({super.key,});

  @override
  Widget build(BuildContext context) {

    final alertProvider = Provider.of<AlertsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        backgroundColor: const Color(0xFF424242),
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
                  onChanged: (value) => alertProvider.toggleAlerts(value, context),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
*/

//Alert Provider
class AlertsProvider extends ChangeNotifier {
  
  bool _showAlerts = true;
  bool get showAlerts => _showAlerts;

  AlertsProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _showAlerts = prefs.getBool('showAlerts') ?? true;
    notifyListeners();
  }

  void toggleAlerts(bool value, BuildContext context) async {
    _showAlerts = value;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('showAlerts', _showAlerts);
    notifyListeners();

    //Snackbar message
    final message = _showAlerts ? 'Alert Messages Enabled' : 'Alert Messages Disabled';
    ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Center(
          child: Text(message),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(
          horizontal: 40.0,
          vertical: 20.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}