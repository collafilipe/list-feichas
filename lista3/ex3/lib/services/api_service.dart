import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/contact.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final String message;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.message,
  });
}

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000'; 
  static const String contactsEndpoint = '/contatos';
  static const Duration timeout = Duration(seconds: 30);

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<ApiResponse<List<Contact>>> getAllContacts() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$contactsEndpoint'),
            headers: _headers,
          )
          .timeout(timeout);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final List<dynamic> contactsJson = responseData['data'];
        final List<Contact> contacts = contactsJson
            .map((json) => Contact.fromJson(json))
            .toList();

        return ApiResponse<List<Contact>>(
          success: true,
          data: contacts,
          message: responseData['message'] ?? 'Contatos recuperados com sucesso',
        );
      } else {
        return ApiResponse<List<Contact>>(
          success: false,
          error: responseData['error'] ?? 'Erro desconhecido',
          message: responseData['message'] ?? 'Falha ao buscar contatos',
        );
      }
    } on SocketException {
      return ApiResponse<List<Contact>>(
        success: false,
        error: 'Erro de conexão',
        message: 'Verifique sua conexão com a internet',
      );
    } on http.ClientException {
      return ApiResponse<List<Contact>>(
        success: false,
        error: 'Erro de cliente HTTP',
        message: 'Falha na comunicação com o servidor',
      );
    } catch (e) {
      return ApiResponse<List<Contact>>(
        success: false,
        error: 'Erro inesperado',
        message: 'Ocorreu um erro inesperado: $e',
      );
    }
  }

  static Future<ApiResponse<Contact>> getContactById(String id) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$contactsEndpoint/$id'),
            headers: _headers,
          )
          .timeout(timeout);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final Contact contact = Contact.fromJson(responseData['data']);

        return ApiResponse<Contact>(
          success: true,
          data: contact,
          message: responseData['message'] ?? 'Contato encontrado com sucesso',
        );
      } else {
        return ApiResponse<Contact>(
          success: false,
          error: responseData['error'] ?? 'Erro desconhecido',
          message: responseData['message'] ?? 'Contato não encontrado',
        );
      }
    } on SocketException {
      return ApiResponse<Contact>(
        success: false,
        error: 'Erro de conexão',
        message: 'Verifique sua conexão com a internet',
      );
    } catch (e) {
      return ApiResponse<Contact>(
        success: false,
        error: 'Erro inesperado',
        message: 'Ocorreu um erro inesperado: $e',
      );
    }
  }

  static Future<ApiResponse<Contact>> createContact(Contact contact) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$contactsEndpoint'),
            headers: _headers,
            body: json.encode({
              'nome': contact.nome,
              'telefone': contact.telefone,
              'email': contact.email,
            }),
          )
          .timeout(timeout);

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        final Contact createdContact = Contact.fromJson(responseData['data']);

        return ApiResponse<Contact>(
          success: true,
          data: createdContact,
          message: responseData['message'] ?? 'Contato criado com sucesso',
        );
      } else {
        return ApiResponse<Contact>(
          success: false,
          error: responseData['error'] ?? 'Erro desconhecido',
          message: responseData['message'] ?? 'Falha ao criar contato',
        );
      }
    } on SocketException {
      return ApiResponse<Contact>(
        success: false,
        error: 'Erro de conexão',
        message: 'Verifique sua conexão com a internet',
      );
    } catch (e) {
      return ApiResponse<Contact>(
        success: false,
        error: 'Erro inesperado',
        message: 'Ocorreu um erro inesperado: $e',
      );
    }
  }

  // Atualizar contato
  static Future<ApiResponse<Contact>> updateContact(Contact contact) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$contactsEndpoint/${contact.id}'),
            headers: _headers,
            body: json.encode({
              'nome': contact.nome,
              'telefone': contact.telefone,
              'email': contact.email,
            }),
          )
          .timeout(timeout);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final Contact updatedContact = Contact.fromJson(responseData['data']);

        return ApiResponse<Contact>(
          success: true,
          data: updatedContact,
          message: responseData['message'] ?? 'Contato atualizado com sucesso',
        );
      } else {
        return ApiResponse<Contact>(
          success: false,
          error: responseData['error'] ?? 'Erro desconhecido',
          message: responseData['message'] ?? 'Falha ao atualizar contato',
        );
      }
    } on SocketException {
      return ApiResponse<Contact>(
        success: false,
        error: 'Erro de conexão',
        message: 'Verifique sua conexão com a internet',
      );
    } catch (e) {
      return ApiResponse<Contact>(
        success: false,
        error: 'Erro inesperado',
        message: 'Ocorreu um erro inesperado: $e',
      );
    }
  }

  static Future<ApiResponse<Contact>> deleteContact(String id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl$contactsEndpoint/$id'),
            headers: _headers,
          )
          .timeout(timeout);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final Contact deletedContact = Contact.fromJson(responseData['data']);

        return ApiResponse<Contact>(
          success: true,
          data: deletedContact,
          message: responseData['message'] ?? 'Contato excluído com sucesso',
        );
      } else {
        return ApiResponse<Contact>(
          success: false,
          error: responseData['error'] ?? 'Erro desconhecido',
          message: responseData['message'] ?? 'Falha ao excluir contato',
        );
      }
    } on SocketException {
      return ApiResponse<Contact>(
        success: false,
        error: 'Erro de conexão',
        message: 'Verifique sua conexão com a internet',
      );
    } catch (e) {
      return ApiResponse<Contact>(
        success: false,
        error: 'Erro inesperado',
        message: 'Ocorreu um erro inesperado: $e',
      );
    }
  }

  static Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$contactsEndpoint'))
          .timeout(Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}