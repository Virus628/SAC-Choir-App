import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Returns the signed-in user if one exists, otherwise prompts the admin to
/// sign in with email + password. Returns null if cancelled or sign-in failed.
Future<User?> ensureAdminSignedIn(BuildContext context) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) return currentUser;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? errorText;
  bool isBusy = false;

  final result = await showDialog<User?>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        Future<void> signIn() async {
          setDialogState(() {
            isBusy = true;
            errorText = null;
          });
          try {
            final credential = await FirebaseAuth.instance
                .signInWithEmailAndPassword(
                  email: emailController.text.trim(),
                  password: passwordController.text,
                );
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop(credential.user);
            }
          } on FirebaseAuthException catch (e) {
            // Reset busy state so the dialog can be retried.
            if (dialogContext.mounted) {
              setDialogState(() {
                isBusy = false;
                errorText = switch (e.code) {
                  'user-not-found' ||
                  'wrong-password' ||
                  'invalid-credential' ||
                  'invalid-login-credentials' =>
                    'Incorrect email or password.',
                  'user-disabled' => 'This admin account has been disabled.',
                  'operation-not-allowed' =>
                    'Email/password sign-in is not enabled in Firebase Auth.',
                  'invalid-email' => 'That email address is not valid.',
                  _ => 'Sign-in failed: ${e.code} (${e.message})',
                };
              });
            }
          } catch (e) {
            if (dialogContext.mounted) {
              setDialogState(() {
                isBusy = false;
                errorText = 'Unexpected error: $e';
              });
            }
          }
        }

        return AlertDialog(
          title: const Text('Admin Sign In'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => signIn(),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isBusy
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isBusy ? null : signIn,
              child: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign In'),
            ),
          ],
        );
      },
    ),
  );

  emailController.dispose();
  passwordController.dispose();
  return result;
}

Future<void> signOutAdmin() => FirebaseAuth.instance.signOut();