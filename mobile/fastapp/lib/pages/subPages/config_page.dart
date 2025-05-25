import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfiguracoesWidget extends StatefulWidget {
  final String nome;
  final String email;
  final String id;
  final String token;
  final String? imagemUrl; // <- novo parâmetro

  const ConfiguracoesWidget({
    super.key,
    required this.nome,
    required this.email,
    required this.id,
    required this.token,
    this.imagemUrl, // <- incluir aqui
  });

  @override
  State<ConfiguracoesWidget> createState() => _ConfiguracoesWidgetState();
}

class _ConfiguracoesWidgetState extends State<ConfiguracoesWidget> {
  bool tokenVisivel = false;
  File? fotoUsuario;

  final ImagePicker _picker = ImagePicker();

  Future<void> _trocarFoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Selecionar imagem da galeria
      final XFile? imagemSelecionada = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (imagemSelecionada != null) {
        final imagem = File(imagemSelecionada.path);

        setState(() {
          fotoUsuario = imagem;
        });

        await _enviarImagemParaServidor(imagem, prefs.getString('token') ?? '');
      }
    } catch (e) {
      debugPrint('Erro ao escolher imagem: $e');
    }
  }

  Future<void> _enviarImagemParaServidor(File imagem, String token) async {

    final uri = Uri.parse('http://10.0.2.2:5000/api/tecnico/upload_foto');

    final request =
        http.MultipartRequest('POST', uri)
          ..fields['token'] = token
          ..files.add(await http.MultipartFile.fromPath('imagem', imagem.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      debugPrint('Imagem enviada com sucesso!');
      // Aqui você pode atualizar o estado ou recarregar a imagem
    } else {
      debugPrint('Erro ao enviar imagem. Código: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações', textScaleFactor: 1.3),
        backgroundColor: const Color.fromARGB(148, 148, 83, 253),
      ),
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Row(
              children: [
                // Foto do usuário com botão para trocar
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage:
                          widget.imagemUrl != null &&
                                  widget.imagemUrl!.isNotEmpty
                              ? NetworkImage(
                                'http://10.0.2.2:5000/static/${widget.imagemUrl}',
                              )
                              : const AssetImage('assets/user_placeholder.png')
                                  as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _trocarFoto,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue,
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                // Dados do usuário (nome, email, id, token)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nome,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(widget.email, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${widget.id}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Token com opção de mostrar/ocultar
                      Row(
                        children: [
                          Text('Token: ', style: const TextStyle(fontSize: 14)),
                          Expanded(
                            child: Text(
                              tokenVisivel
                                  ? widget.token
                                  : widget.token.replaceAll(RegExp(r'.'), '*'),
                              style: const TextStyle(
                                fontSize: 14,
                                letterSpacing: 2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              tokenVisivel
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                tokenVisivel = !tokenVisivel;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Rodapé com versão do app
            Text(
              'Versão do app: 1.21.90.25',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
