import 'package:flutter/material.dart';
import "package:amplify_flutter/amplify.dart";
import "package:amplify_auth_cognito/amplify_auth_cognito.dart";
import './login_page.dart';
import './sign_up.dart';
import "./auth_service.dart";
import "./verification_page.dart";
import "./app_session.dart";
import "./amplifyconfiguration.dart";

void main() {
  runApp(MyApp());
}

// 1
class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final _authService = AuthService();

  @override
  void initState() {
    _configureAmplify();
    super.initState();
    _authService.showLogin();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Gallery App',
      theme: ThemeData(visualDensity: VisualDensity.adaptivePlatformDensity),
      // 2
    home: StreamBuilder<AuthState>(
      // 2
      stream: _authService.authStateController.stream,
      builder: (context, snapshot) {
        // 3
        if (snapshot.hasData) {
          return Navigator(
            pages: [
              // 4
              // Show Login Page
              if (snapshot.data!.authFlowStatus == AuthFlowStatus.login)
                MaterialPage(
                  child: LoginPage(
                      key: UniqueKey(),
                      didProvideCredentials: _authService.loginWithCredentials,
                      shouldShowSignUp: _authService.showSignUp))

              // 5
              // Show Sign Up Page
              else if (snapshot.data!.authFlowStatus == AuthFlowStatus.signUp)
                MaterialPage(
                  child: SignUpPage(
                      key: UniqueKey(),
                      didProvideCredentials: _authService.signUpWithCredentials,
                      shouldShowLogin: _authService.showLogin))

              else if (snapshot.data!.authFlowStatus == AuthFlowStatus.verification)
                MaterialPage(child: VerificationPage(
                  key: UniqueKey(),
                  didProvideVerificationCode: _authService.verifyCode))

              else if (snapshot.data!.authFlowStatus == AuthFlowStatus.session)
                MaterialPage(
                    child: AppSession(authService: _authService))
            ],
            onPopPage: (route, result) => route.didPop(result),
          );
        } else {
          // 6
          return Container(
            alignment: Alignment.center,
            child: CircularProgressIndicator(),
          );
        }
      }),
    );
  }

  void _configureAmplify() async {
    Amplify.addPlugin(AmplifyAuthCognito());
    try {
      await Amplify.configure(amplifyconfig);
      print('Successfully configured Amplify 🎉');
    } catch (e) {
      // MONITORAR ISSO
      print('Could not configure Amplify ☠️');
    }
    _authService.checkAuthStatus();
  }

}