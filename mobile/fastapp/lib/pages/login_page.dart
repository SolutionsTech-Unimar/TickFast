import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controller único para e-mail ou ID
  final TextEditingController loginController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            transform: GradientRotation(2.53), // ~145 graus em rad
            colors: [
              Color(0xFF5F0FD7), // Roxo
              Color(0xFF3A3A39), // Cinza escuro
              Colors.black,      // Preto
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  "Login do Técnico",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                // Campo de login (ID ou E-mail)
                TextField(
                  controller: loginController,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "ID ou E-mail",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white38),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Campo de senha
                TextField(
                  controller: senhaController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Senha",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white38),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Botão de login
                ElevatedButton(
                  onPressed: () {
                    final login = loginController.text.trim();
                    final senha = senhaController.text.trim();

                    if (login.isNotEmpty && senha.isNotEmpty) {
                      fazerLogin(login, senha, context);
                    } else {
                      showDialog(
                        context: context,
                        builder: (_) => const AlertDialog(
                          title: Text('Erro'),
                          content: Text('Preencha todos os campos.'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F0FD7),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Entrar",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Função para autenticar na API Flask
Future<void> fazerLogin(String login, String senha, BuildContext context) async {
  final url = Uri.parse('http://10.0.2.2:5000/api/login'); 

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': login, // Backend trata como ID OU email
        'senha': senha,
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['statusApi'] == 'sucesso') {
      // Salva dados do técnico localmente (SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', responseData['token']);
      await prefs.setString('imagem', responseData['imagem']);
      await prefs.setString('id', responseData['id'].toString());
      await prefs.setString('nome', responseData['nome']);
      await prefs.setString('email', responseData['email']);
      await prefs.setString('horaEntrada', responseData['horaEntrada']);
      await prefs.setString('horaSaida', responseData['horaSaida']);
      await prefs.setString('status', responseData['status']);

      // Redireciona para home
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Erro'),
          content: Text(responseData['mensagem'] ?? 'Erro ao logar'),
        ),
      );
    }
  } catch (e) {
    // Erros de conexão com o servidor
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('Erro'),
        content: Text('Não foi possível conectar ao servidor.'),
      ),
    );
  }
}
