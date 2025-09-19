# Gerenciador de Contatos - Flutter + Node.js

Este projeto implementa um aplicativo completo de gerenciamento de contatos com sincronização entre uma API Node.js e armazenamento local SQLite no Flutter.

## 📋 Funcionalidades

### API Node.js (Backend)
- ✅ Rotas CRUD completas (GET, POST, PUT, DELETE)
- ✅ Armazenamento em arquivo JSON no servidor
- ✅ Tratamento de erros e validações
- ✅ CORS habilitado para comunicação com Flutter
- ✅ Respostas padronizadas com status de sucesso/erro

### App Flutter (Frontend)
- ✅ Interface intuitiva para listar contatos
- ✅ Formulário para adicionar/editar contatos
- ✅ Armazenamento local com SQLite
- ✅ Sincronização automática com API
- ✅ Tratamento de erros e indicadores de carregamento
- ✅ Funciona offline (salva localmente quando API não está disponível)
- ✅ Pull-to-refresh para atualizar contatos
- ✅ Confirmação para exclusão de contatos

## 🚀 Como executar

### Pré-requisitos
- Node.js instalado
- Flutter SDK instalado
- Emulador Android ou dispositivo físico

### 1. Executar API Node.js

```bash
cd api_contatos
node index.js
```

A API estará disponível em: http://localhost:3000

### 2. Executar App Flutter

```bash
cd ex3
flutter pub get
flutter run
```

O aplicativo será executado no emulador/dispositivo conectado.

## 📱 Como usar o App

1. **Primeira execução**: O app tentará sincronizar com a API
2. **Adicionar contato**: Toque no botão + e preencha o formulário
3. **Editar contato**: Toque em um contato da lista ou use o menu
4. **Excluir contato**: Use o menu de contexto (3 pontos) e confirme
5. **Sincronizar**: Toque no ícone de sincronização no AppBar
6. **Atualizar**: Puxe a lista para baixo (pull-to-refresh)

## 🔧 Características Técnicas

### Sincronização Inteligente
- **Online**: Todas as operações são sincronizadas imediatamente com a API
- **Offline**: Dados são salvos localmente e sincronizados quando a conexão for restabelecida
- **Tratamento de Erros**: Mensagens informativas para diferentes cenários

### Arquitetura
```
lib/
├── models/
│   └── contact.dart              # Modelo de dados
├── services/
│   ├── api_service.dart          # Comunicação com API
│   ├── database_helper.dart      # SQLite local
│   └── contact_service.dart      # Lógica de sincronização
└── screens/
    ├── contacts_screen.dart      # Tela principal
    └── contact_form_screen.dart  # Formulário
```

### API Endpoints
- `GET /contatos` - Listar todos os contatos
- `GET /contatos/:id` - Buscar contato por ID
- `POST /contatos` - Criar novo contato
- `PUT /contatos/:id` - Atualizar contato
- `DELETE /contatos/:id` - Excluir contato

## 📊 Estrutura de Dados

### Contato
```json
{
  "id": "1640995200000",
  "nome": "João Silva",
  "telefone": "(11) 99999-9999",
  "email": "joao@email.com",
  "createdAt": "2023-01-01T12:00:00.000Z",
  "updatedAt": "2023-01-01T12:00:00.000Z"
}
```

## 🛡️ Tratamento de Erros

O aplicativo implementa tratamento robusto de erros:

- **Sem conexão**: Dados são salvos localmente
- **Erro na API**: Operação continua localmente com aviso
- **Validações**: Campos obrigatórios e formato de email
- **Feedback visual**: Indicadores de carregamento e mensagens informativas

## 🔍 Testando

1. **Teste offline**: Desligue o servidor e teste as operações
2. **Teste de sincronização**: Religue o servidor e sincronize
3. **Teste de validação**: Tente salvar contatos com dados inválidos
4. **Teste de performance**: Adicione vários contatos

## 🐛 Solucionando Problemas

### API não conecta
- Verifique se o servidor Node.js está rodando na porta 3000
- Para dispositivo físico, altere a URL base no `api_service.dart`

### App não compila
- Execute `flutter clean && flutter pub get`
- Verifique se todas as dependências estão atualizadas

### Emulador não aparece
- Execute `flutter devices` para ver dispositivos disponíveis
- Inicie um emulador Android/iOS

## 📦 Dependências

### Flutter
- `http`: Requisições HTTP
- `sqflite`: Banco de dados SQLite
- `path`: Utilitários de caminho

### Node.js
- `express`: Framework web
- `cors`: Cross-Origin Resource Sharing
- `body-parser`: Parser de corpo de requisições

## 🎯 Próximas Melhorias

- [ ] Busca e filtros nos contatos
- [ ] Categorias/grupos de contatos
- [ ] Backup e restauração
- [ ] Validação de telefone por país
- [ ] Fotos de perfil
- [ ] Integração com contatos do sistema