import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import './MyHomePage.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _storage = FlutterSecureStorage();
  bool _loading = false;
  String? _errorMessage;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _checkUserVerification();
  }

  Future<void> _checkUserVerification() async {
    bool verified = await verifyUserData();
    if (verified) {
      // L’utilisateur est déjà vérifié, on le redirige vers la home
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MyHomePage(title: 'Accueil')),
        );
      }
    }
  }

  // Votre fonction verifyUserData() ici (inchangée)

  // Le reste de votre code (login, build, etc.) ...

  Future<bool> verifyUserData() async {
    // final token = await _storage.read(key: 'auth_token');
    String? token = await _storage.read(key: 'auth_token');
    // token = "nouvelle_valeur"; // valide si besoin

    if (token == null || token.isEmpty) {
      print("Token non trouvé en local");
      return false;
    }

    final url = Uri.parse(
        'https://backend-mega-book-theta.vercel.app/api/getDataUserApp'); // Remplacez par votre URL

    final body = jsonEncode({
      'token': token,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['reponse'] == true) {
          final tokenJwt = data['tokenJwt'];
          if (tokenJwt != null && tokenJwt.isNotEmpty) {
            await _storage.write(key: 'auth_token', value: tokenJwt);
            print("Token JWT stocké localement");
          }
          return true;
        } else {
          print("Utilisateur non vérifié");
          return false;
        }
      } else {
        print("Erreur serveur : ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Erreur réseau : $e");
      return false;
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final url = Uri.parse(
        'https://backend-mega-book-theta.vercel.app/api/auth/signin'); // Remplacez par votre URL API
    final body = jsonEncode({
      'objectUser': {
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
      }
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['reponse'] == true) {
        final token = data['token'];
        await _storage.write(key: 'auth_token', value: token);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyHomePage(title: 'Accueil'),
          ),
        );

        // Redirection vers la route '/'
        // Navigator.of(context).pushReplacementNamed('/');
      } else {
        setState(() {
          _errorMessage = 'Email ou mot de passe incorrect.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur réseau, veuillez réessayer.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 100, color: Colors.blueAccent),
              SizedBox(height: 32),
              Text(
                'Connexion',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent),
              ),
              SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email),
                        labelText: 'Email',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Veuillez entrer votre email';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                          return 'Email invalide';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Mot de passe
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock),
                        labelText: 'Mot de passe',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre mot de passe';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 24),

                    // Bouton connexion
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _loading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Se connecter',
                                style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      SizedBox(height: 16),
                      Text(_errorMessage!, style: TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
