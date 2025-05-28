import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fastapp/services/location_service.dart';
import 'package:fastapp/services/status_service.dart';
import 'package:flutter/foundation.dart';
import 'package:fastapp/pages/subPages/tickets_page.dart';
import 'package:fastapp/pages/subPages/config_page.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:ui';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String nome = '';
  String token = '';
  String id = '';
  String email = '';
  String horaEntrada = '';
  String horaSaida = '';
  int selectedIndex = 0;
  String status = 'Inativo';
  Timer? _timer;
  String? imagem = '';
  String horasRestantes = '00:00';
  DateTime dataRelevante = DateTime.now();
  bool atividadeEncerrada = false;
  bool statusJaAtualizado = false;
  String statusAtual = 'inativo';
  String ultimoStatusEnviado = ''; // começa vazio para garantir envio inicial
  String dataFormatada = DateFormat(
    "d 'de' MMMM",
    'pt_BR',
  ).format(DateTime.now());
  int minutosExtras = 0;
  bool extensaoConfirmada = false;
  bool extensaoPerguntada = false;
  DateTime? horaLimiteFinal;
  

  final List<String> menuItems = ['Tickets', 'Ponto', 'Configurações'];

  @override
  void initState() {
    super.initState();
    iniciarContador();
    carregarDados();
    LocationService.startSendingLocation();
  }

  String _calcularHorasRestantes(DateTime fim, DateTime agora) {
    final diferenca = fim.difference(agora);
    final horas = diferenca.inHours.toString().padLeft(2, '0');
    final minutos = (diferenca.inMinutes % 60).toString().padLeft(2, '0');
    return '$horas:$minutos';
  }

  void _mostrarConfirmacaoEncerramento() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Confirmar encerramento',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Deseja encerrar suas atividades por hoje?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                child: const Text('Não'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('Sim'),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    LocationService.stopSendingLocation();
                    atualizarStatus('inativo');
                    AtividadeNoServidor();
                    minutosExtras == 0;
                    atividadeEncerrada = true;
                    horasRestantes = '00:00';
                    dataRelevante = DateTime.now().add(const Duration(days: 1));
                    dataFormatada = DateFormat(
                      "d 'de' MMMM",
                      'pt_BR',
                    ).format(dataRelevante);
                  });
                },
              ),
            ],
          ),
    );
  }

  void _mostrarPerguntaExtensao() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.black,
            title: const Text(
              'Deseja estender o expediente?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Faltam menos de 3 minutos. Deseja adicionar 30 minutos extras? \n\nIsso será contabilizado e enviado ao RH',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                child: const Text('Sim'),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    minutosExtras += 30;
                    extensaoConfirmada = true;
                    atualizarStatus('ocupado');
                    AtividadeNoServidor();
                  });
                },
              ),
              TextButton(
                child: const Text('Não'),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    extensaoConfirmada = true;
                  });
                },
              ),
            ],
          ),
    );
  }

  void iniciarContador() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final agora = DateTime.now();
      final hoje = DateTime(agora.year, agora.month, agora.day);

      if (horaEntrada.isEmpty || horaSaida.isEmpty) {
        setState(() {
          atividadeEncerrada = true;
          horasRestantes = '00:00';
        });
        return;
      }

      if (hoje ==
          DateTime(
            dataRelevante.year,
            dataRelevante.month,
            dataRelevante.day,
          )) {
        try {
          final entrada = DateFormat('HH:mm').parse(horaEntrada);
          final saida = DateFormat('HH:mm').parse(horaSaida);

          final entradaHoje = DateTime(
            agora.year,
            agora.month,
            agora.day,
            entrada.hour,
            entrada.minute,
          );
          final saidaHoje = DateTime(
            agora.year,
            agora.month,
            agora.day,
            saida.hour,
            saida.minute,
          );

          horaLimiteFinal = saidaHoje.add(Duration(minutes: minutosExtras));
          
          // Verifica se estamos dentro do horário
          if (agora.isAfter(entradaHoje) && agora.isBefore(saidaHoje)) {
            statusAtual = 'ativo';
            setState(() {
              atividadeEncerrada = false;
              horasRestantes = _calcularHorasRestantes(saidaHoje, agora);
            });
          } else if(minutosExtras > 0) {
            return;
          }else{
            statusAtual = 'inativo';
            setState(() {
              atividadeEncerrada = true;
              horasRestantes = '00:00';
            });
          }

          
          // Calcula novo horário final com possíveis minutos extras
          final fimEfetivo = horaLimiteFinal ?? saidaHoje;
          if (agora.isBefore(fimEfetivo) && agora.isAfter(entradaHoje)) {
            setState(() {
              horasRestantes = _calcularHorasRestantes(fimEfetivo, agora);
            });

            final diferenca = fimEfetivo.difference(agora);
            if (diferenca.inMinutes <= 3 && !extensaoPerguntada) {
              extensaoPerguntada = true;
              _mostrarPerguntaExtensao();
            }
          } else if (!extensaoConfirmada) {
            // Espera confirmação
            return;
          } else {
            setState(() {
              atividadeEncerrada = true;
              horasRestantes = '00:00';
              statusAtual = 'inativo';
            });
            if (statusAtual != ultimoStatusEnviado) {
              await atualizarStatus(statusAtual);
              await AtividadeNoServidor();
              ultimoStatusEnviado = statusAtual;
            }
          }

          // Envia para servidor apenas se mudou o status
          if (statusAtual != ultimoStatusEnviado) {
            await atualizarStatus(statusAtual);
            await AtividadeNoServidor();
            debugPrint('Status alterado para $statusAtual');
            ultimoStatusEnviado = statusAtual;
          }
        } catch (e) {
          debugPrint('Erro ao parsear hora: $e');
          setState(() {
            atividadeEncerrada = true;
            horasRestantes = '00:00';
          });
        }
      } else {
        setState(() {
          atividadeEncerrada = true;
          horasRestantes = '00:00';
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? '';
      id = prefs.getString('id') ?? '';
      nome = prefs.getString('nome') ?? '';
      email = prefs.getString('email') ?? '';
      imagem = prefs.getString('imagem') ?? '';
      horaEntrada = prefs.getString('horaEntrada') ?? '';
      horaSaida = prefs.getString('horaSaida') ?? '';
      status = prefs.getString('status') ?? 'inativo';
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    LocationService.stopSendingLocation();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> atualizarStatus(String novoStatus) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('status', novoStatus);
    setState(() {
      status = novoStatus;
    });
  }

  Widget buildPontoTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text(
                dataFormatada,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Divider(color: Color.fromARGB(255, 120, 34, 250)),
          const SizedBox(height: 30),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Sua hora de entrada: $horaEntrada',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Color.fromARGB(255, 241, 226, 255)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Sua hora de saída: $horaSaida',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          const SizedBox(height: 60),
          Column(
            children: [
              const Text(
                'Horas restantes',
                style: TextStyle(fontSize: 22, color: Colors.white70),
              ),
              const SizedBox(height: 13),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    horasRestantes,
                    style: const TextStyle(
                      fontSize: 66,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                    ),
                    onPressed:
                        (atividadeEncerrada || minutosExtras >= 120)
                            ? null
                            : () {
                              setState(() {
                                minutosExtras += 30;
                                atualizarStatus('ocupado');
                                AtividadeNoServidor();
                                statusAtual = 'ocupado';
                                extensaoConfirmada = true;
                              });
                            },
                  ),
                ],
              ),
              if (minutosExtras > 0)
                Text(
                  'Horas extras: ${minutosExtras ~/ 60}h ${minutosExtras % 60}min',
                  style: const TextStyle(fontSize: 16, color: Colors.amber),
                ),
            ],
          ),
          const SizedBox(height: 70),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  atividadeEncerrada
                      ? null
                      : () => _mostrarConfirmacaoEncerramento(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Encerrar atividade',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildContent() {
    switch (selectedIndex) {
      case 0:
        return TicketsWidget(tecnicoId:  int.tryParse(id) ?? 0, token: token);
      case 1:
        return buildPontoTab();
      case 2:
         return ConfiguracoesWidget(nome: nome,email: email,id: id,token: token,onFotoAlterada: carregarDados,);
      default:
        return Container();
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ativo':
        return Colors.green;
      case 'ocupado':
        return Colors.red;
      case 'inativo':
      default:
        return Colors.grey;
    }
  }

  String capitalize(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            height: 200,
            width: double.infinity,
            color: const Color.fromARGB(255, 95, 15, 215),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                       CircleAvatar(
                        radius: 30,
                         backgroundImage:
                          imagem != null && imagem!.isNotEmpty
                              ? NetworkImage(
                                'http://10.0.2.2:5000/static/fotos_perfil/$imagem',
                              )
                              : const AssetImage('assets/user_placeholder.png')
                                  as ImageProvider,
                        backgroundColor: Colors.white,
                      ),
                      Positioned(
                        left: 36,
                        bottom: -6, // move tudo para mais abaixo
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: getStatusColor(status),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              capitalize(status),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: const Color.fromARGB(255, 192, 192, 192),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Olá, $nome',
                      style: const TextStyle(fontSize: 30, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: logout,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(menuItems.length, (index) {
                return GestureDetector(
                  onTap: () => setState(() => selectedIndex = index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      menuItems[index],
                      style: TextStyle(
                        color:
                            selectedIndex == index
                                ? Colors.white
                                : Colors.white70,
                        fontWeight:
                            selectedIndex == index
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: buildContent(),
            ),
          ),
        ],
      ),
    );
  }
}
