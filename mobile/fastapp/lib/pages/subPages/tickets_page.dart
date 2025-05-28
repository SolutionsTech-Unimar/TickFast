import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TicketsWidget extends StatefulWidget {
  final int tecnicoId;
  final String token;

  const TicketsWidget({super.key, required this.tecnicoId, required this.token});

  @override
  State<TicketsWidget> createState() => _TicketsWidgetState();
}

class _TicketsWidgetState extends State<TicketsWidget> {
  List<Map<String, dynamic>> tickets = [];

  @override
  void initState() {
    super.initState();
    carregarTickets();
  }

  Future<void> carregarTickets() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/tecnico/${widget.tecnicoId}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          tickets = List<Map<String, dynamic>>.from(data['tickets']);
        });
      } else {
        debugPrint("Erro ao carregar tickets: ${response.body}");
      }
    } catch (e) {
      debugPrint("Erro ao buscar tickets: $e");
    }
  }

  Future<void> resolverTicket(int ticketId) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/ticket/$ticketId/fechar'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          tickets.removeWhere((ticket) => ticket['id'] == ticketId);
        });
      } else {
        debugPrint("Erro ao resolver ticket: ${response.body}");
      }
    } catch (e) {
      debugPrint("Erro ao enviar requisição: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 38),
        Text('Você possui ${tickets.length} ticket(s)', style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return ExpansionTile(
                title: Text("Ticket #${ticket['id']} - Status: ${ticket['status']}"),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ticket['descricao'] ?? 'Sem descrição'),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle),
                          label: const Text("Resolver", style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () => resolverTicket(ticket['id']),
                        )
                      ],
                    ),
                  )
                ],
              );
            },
          ),
        )
      ],
    );
  }
}
