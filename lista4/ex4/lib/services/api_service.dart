import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000'; 

  static Future<List<Article>> fetchNoticias() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/noticias'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> noticiasJson = data['data'];
          return noticiasJson.map((json) => Article.fromJson(json)).toList();
        } else {
          throw Exception('Resposta da API inválida');
        }
      } else {
        throw Exception('Falha ao carregar notícias: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
}