import '../models/contact.dart';
import '../services/database_helper.dart';
import '../services/api_service.dart';

class ContactService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<List<Contact>> getAllContacts() async {
    try {
      return await _databaseHelper.getAllContacts();
    } catch (e) {
      throw Exception('Erro ao buscar contatos locais: $e');
    }
  }

  Future<Contact?> getContactById(String id) async {
    try {
      return await _databaseHelper.getContactById(id);
    } catch (e) {
      throw Exception('Erro ao buscar contato por ID: $e');
    }
  }

  Future<Contact> createContact(Contact contact) async {
    try {
      final apiResponse = await ApiService.createContact(contact);
      
      if (apiResponse.success && apiResponse.data != null) {
        final createdContact = apiResponse.data!;
        await _databaseHelper.insertContact(createdContact);
        return createdContact;
      } else {
        final localContact = contact.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );
        
        await _databaseHelper.insertContact(localContact);
        
        throw Exception('Contato salvo localmente, mas falhou na sincronização: ${apiResponse.message}');
      }
    } catch (e) {
      if (e.toString().contains('Contato salvo localmente')) {
        rethrow;
      }
      
      final localContact = contact.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      await _databaseHelper.insertContact(localContact);
      throw Exception('Contato salvo localmente. Erro na API: $e');
    }
  }

  Future<Contact> updateContact(Contact contact) async {
    try {
      final apiResponse = await ApiService.updateContact(contact);
      
      if (apiResponse.success && apiResponse.data != null) {
        final updatedContact = apiResponse.data!;
        await _databaseHelper.updateContact(updatedContact);
        return updatedContact;
      } else {
        final localContact = contact.copyWith(
          updatedAt: DateTime.now().toIso8601String(),
        );
        
        await _databaseHelper.updateContact(localContact);
        
        throw Exception('Contato atualizado localmente, mas falhou na sincronização: ${apiResponse.message}');
      }
    } catch (e) {
      if (e.toString().contains('Contato atualizado localmente')) {
        rethrow;
      }
      
      final localContact = contact.copyWith(
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      await _databaseHelper.updateContact(localContact);
      throw Exception('Contato atualizado localmente. Erro na API: $e');
    }
  }

  Future<void> deleteContact(String id) async {
    try {
      final apiResponse = await ApiService.deleteContact(id);
      
      if (apiResponse.success) {
        await _databaseHelper.deleteContact(id);
      } else {
        await _databaseHelper.deleteContact(id);
        
        throw Exception('Contato deletado localmente, mas falhou na sincronização: ${apiResponse.message}');
      }
    } catch (e) {
      if (e.toString().contains('Contato deletado localmente')) {
        rethrow;
      }
      
      await _databaseHelper.deleteContact(id);
      throw Exception('Contato deletado localmente. Erro na API: $e');
    }
  }

  Future<void> syncWithApi() async {
    try {
      final hasConnection = await ApiService.checkConnection();
      if (!hasConnection) {
        throw Exception('Sem conexão com o servidor');
      }

      final apiResponse = await ApiService.getAllContacts();
      
      if (apiResponse.success && apiResponse.data != null) {
        final apiContacts = apiResponse.data!;
        
        await _databaseHelper.clearAllContacts();
        
        if (apiContacts.isNotEmpty) {
          await _databaseHelper.insertMultipleContacts(apiContacts);
        }
      } else {
        throw Exception('Falha ao buscar contatos da API: ${apiResponse.message}');
      }
    } catch (e) {
      throw Exception('Erro na sincronização: $e');
    }
  }

  Future<int> getContactsCount() async {
    try {
      return await _databaseHelper.getContactsCount();
    } catch (e) {
      throw Exception('Erro ao contar contatos: $e');
    }
  }

  Future<bool> checkApiConnection() async {
    try {
      return await ApiService.checkConnection();
    } catch (e) {
      return false;
    }
  }
}