import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tarefa.dart';

class TarefaService {
  // Para testar em um emulador Android, use o IP 10.0.2.2 que se refere ao localhost da sua máquina
  // Para testar em um dispositivo físico, use o IP da sua máquina na rede local
  // Para testar no navegador, use localhost
  final String baseUrl = 'http://10.0.2.2:3000/tarefas';

  Future<List<Tarefa>> getTarefas() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<Tarefa> tarefas = body.map((item) => Tarefa.fromJson(item)).toList();
        return tarefas;
      } else {
        throw Exception('Falha ao carregar tarefas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<Tarefa> createTarefa(String titulo, String descricao) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'titulo': titulo,
          'descricao': descricao,
        }),
      );

      if (response.statusCode == 201) {
        return Tarefa.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Falha ao criar tarefa: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<Tarefa> updateTarefa(Tarefa tarefa) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${tarefa.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(tarefa.toJson()),
      );

      if (response.statusCode == 200) {
        return Tarefa.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Falha ao atualizar tarefa: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<void> deleteTarefa(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));

      if (response.statusCode != 200) {
        throw Exception('Falha ao deletar tarefa: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
}
