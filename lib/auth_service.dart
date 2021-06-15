import 'dart:async';
import "package:amplify_flutter/amplify.dart";
import "package:amplify_auth_cognito/amplify_auth_cognito.dart";
import "./auth_credentials.dart";

enum AuthFlowStatus { login, signUp, verification, session }

class AuthState {
  final AuthFlowStatus authFlowStatus;

  AuthState({required this.authFlowStatus});
}

// 3
class AuthService {
  // 4
  final authStateController = StreamController<AuthState>();

  late AuthCredentials _credentials;

  // 5
  void showSignUp() {
    final state = AuthState(authFlowStatus: AuthFlowStatus.signUp);
    authStateController.add(state);
  }

  // 6
  void showLogin() {
    final state = AuthState(authFlowStatus: AuthFlowStatus.login);
    authStateController.add(state);
  }

  // 1
  void loginWithCredentials(AuthCredentials credentials) async {
  try {
    final result = await Amplify.Auth.signIn(username: credentials.username, password: credentials.password);

    if (result.isSignedIn) {
      final state = AuthState(authFlowStatus: AuthFlowStatus.session);
      authStateController.add(state);
    } else {
      print('User could not be signed in');
    }
  } on UserNotConfirmedException catch (authError) {
    print('Could not login - ${authError.message}');
    print('Redirecting to confirmation bang');
    this._credentials = credentials;
    final state = AuthState(authFlowStatus: AuthFlowStatus.verification);
    authStateController.add(state);
  } on UserNotFoundException catch (authError) {
    print('Could not login - ${authError.message}');
    print('Não possui conta');
  } on PasswordResetRequiredException catch (authError){
    print('Flow de Reset - ${authError.message}');
  } on AmplifyException catch (authError) {
    print('Could not login - ${authError.message}');
  }
  }

  // 2
  void signUpWithCredentials(SignUpCredentials credentials) async {
    try {
      // 2
      final userAttributes = {'email': credentials.email};

      // 3
      final result = await Amplify.Auth.signUp(
          username: credentials.username,
          password: credentials.password,
          options: CognitoSignUpOptions(userAttributes: userAttributes));

      if (result.isSignUpComplete) {
        loginWithCredentials(credentials);
      } else {
        // MONITORAR
      }
    
    // 7
    } on AmplifyException catch (authError) {
      // MONITORAR
      print('Failed to sign up - ${authError.message}');
    }
  }

  void verifyCode(String verificationCode) async {
    try {
      final result = await Amplify.Auth.confirmSignUp(username: _credentials.username, confirmationCode: verificationCode);
      if (result.isSignUpComplete) {
        loginWithCredentials(_credentials);
      }
      else {
        // ???
      }

    } on AmplifyException catch (authError) {
      print('Could not verify code - ${authError.message}');
    }
  }

  void logOut() async {
    try {
      await Amplify.Auth.signOut();
      showLogin();
    } on AmplifyException catch (authError) {
      // MONITORAR ISSO
      print('Could not log out - ${authError.message}');
    }
  }

  void checkAuthStatus() async {
    try {
      AuthSession authSession = await Amplify.Auth.fetchAuthSession();
      late AuthFlowStatus redirectedPage;
      if (authSession.isSignedIn) redirectedPage = AuthFlowStatus.session;
      else redirectedPage = AuthFlowStatus.login;

      final state = AuthState(authFlowStatus: redirectedPage);
      authStateController.add(state);

    } catch (e) {
      // MONITORAR ISSO
      final state = AuthState(authFlowStatus: AuthFlowStatus.login);
      authStateController.add(state);
    }
  }
}