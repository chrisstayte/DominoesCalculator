import 'package:dominoes/global/global.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionDialog extends StatefulWidget {
  const PermissionDialog({super.key, required this.hasAccessToCamera});

  final bool hasAccessToCamera;

  @override
  State<PermissionDialog> createState() => _PermissionDialogState();
}

class _PermissionDialogState extends State<PermissionDialog>
    with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Global.ui.cornerRadius),
          ),
          height: 250,
          width: 320,
          child: Column(children: [
            Image.asset(
              'assets/images/camera.png',
              height: 65,
            ),
            Text(
              'Camera Required',
              style: Theme.of(context).textTheme.headline5,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'This app requires access to your camera to be able to count dominoes',
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    // onTap: () => Navigator.pushNamedAndRemoveUntil(
                    //     context, '/', (_) => false),
                    onTap: () =>
                        Navigator.popUntil(context, (route) => route.isFirst),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(Global.ui.cornerRadius),
                        color: Colors.grey.shade500,
                      ),
                      child: const Center(
                        child: Text(
                          'Maybe later',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      openAppSettings();
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(Global.ui.cornerRadius),
                        color: Colors.green.shade400,
                      ),
                      child: const Center(
                        child: Text(
                          'Go to settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            )
          ]),
        ),
      ),
    );
  }
}
