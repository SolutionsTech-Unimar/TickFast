import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fastapp/services/location_service.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String nome = '';
  String email = '';
  String horaEntrada = '00:00';
  String horaSaida = '00:00';
  int selectedIndex = 0;

  final List<String> menuItems = ['Tickets', 'Ponto', 'Configurações'];

  @override
  void initState() {
    super.initState();
    carregarDados();
    LocationService.startSendingLocation();
  }

  Future<void> carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nome = prefs.getString('nome') ?? '';
      email = prefs.getString('email') ?? '';
      horaEntrada = prefs.getString('horaEntrada') ?? '';
      horaSaida = prefs.getString('horaSaida') ?? '';
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget buildContent() {
    switch (selectedIndex) {
      case 0:
        return Center(child: Text('Nenhum ticket disponível'));
      case 1:
        return Center(child: buildPontoTab());
      case 2:
        return Center(child: Text('Configurações da conta'));
      default:
        return Container();
    }
  }

  Widget buildPontoTab() {
    final horaAtual = DateTime.now();
    final horaSaidaParsed = DateFormat('HH:mm').parse(horaSaida);
    final horaEntradaParsed = DateFormat('HH:mm').parse(horaEntrada);

    Duration diferenca = horaSaidaParsed.difference(horaAtual);
    bool atividadeEncerrada =
        diferenca.isNegative || horaAtual.isBefore(horaEntradaParsed);

    String horasRestantes =
        atividadeEncerrada
            ? '00:00'
            : '${diferenca.inHours.toString().padLeft(2, '0')}:${(diferenca.inMinutes % 60).toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Text(
            'Sua hora de entrada: $horaEntrada',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white),
          const SizedBox(height: 10),
          Text(
            'Sua hora de saída: $horaSaida',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                const Text(
                  'Horas restantes',
                  style: TextStyle(fontSize: 20, color: Colors.white70),
                ),
                const SizedBox(height: 10),
                Text(
                  horasRestantes,
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    atividadeEncerrada
                        ? null
                        : () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
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
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                  ),
                                  TextButton(
                                    child: const Text('Sim'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      setState(() {
                                        horaEntrada = '';
                                        horaSaida = '';
                                      });
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Encerrar atividade',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: const AssetImage(
                      'assets/user_placeholder.png',
                    ),
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Olá, $nome',
                      style: const TextStyle(fontSize: 22, color: Colors.white),
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
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
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
