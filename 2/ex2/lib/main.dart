import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';


class Produto {
  final int? id; 
  final int? serverId; 
  final String nome;
  final double preco;
  final String descricao;

  Produto({
    this.id,
    this.serverId,
    required this.nome,
    required this.preco,
    required this.descricao,
  });

  Produto copyWith({
    int? id,
    int? serverId,
    String? nome,
    double? preco,
    String? descricao,
  }) {
    return Produto(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      nome: nome ?? this.nome,
      preco: preco ?? this.preco,
      descricao: descricao ?? this.descricao,
    );
  }

  factory Produto.fromServerJson(Map<String, dynamic> json) {
    return Produto(
      serverId: json['id'] is int ? json['id'] : int.tryParse('${json['id']}'),
      nome: '${json['nome'] ?? ''}',
      preco: (json['preco'] is num) ? (json['preco'] as num).toDouble() : double.tryParse('${json['preco']}') ?? 0.0,
      descricao: '${json['descricao'] ?? ''}',
    );
  }

  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'server_id': serverId,
      'nome': nome,
      'preco': preco,
      'descricao': descricao,
    };
  }

  factory Produto.fromLocalMap(Map<String, dynamic> map) {
    return Produto(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      nome: map['nome'] as String? ?? '',
      preco: (map['preco'] is num) ? (map['preco'] as num).toDouble() : double.tryParse('${map['preco']}') ?? 0.0,
      descricao: map['descricao'] as String? ?? '',
    );
  }
}


class RemoteService {
  static const String baseUrl = 'http://10.0.2.2:3001';

  Future<List<Produto>> fetchProdutos() async {
    final uri = Uri.parse('$baseUrl/produtos');
    final res = await http.get(uri, headers: {'Accept': 'application/json'});

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body) as List;
      return data.map((e) => Produto.fromServerJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Falha ao carregar produtos do servidor (${res.statusCode})');
    }
  }
  
  Future<Produto> addProduto(Produto produto) async {
    final uri = Uri.parse('$baseUrl/produtos');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': produto.nome,
        'preco': produto.preco,
        'descricao': produto.descricao,
      }),
    );

    if (res.statusCode == 201) {
      final data = jsonDecode(res.body);
      return Produto.fromServerJson(data);
    } else {
      throw Exception('Falha ao adicionar produto no servidor (${res.statusCode})');
    }
  }
  
  Future<Produto> updateProduto(Produto produto) async {
    if (produto.serverId == null) {
      throw Exception('Não é possível atualizar um produto sem ID no servidor');
    }
    
    final uri = Uri.parse('$baseUrl/produtos/${produto.serverId}');
    final res = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': produto.nome,
        'preco': produto.preco,
        'descricao': produto.descricao,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return Produto.fromServerJson(data);
    } else {
      throw Exception('Falha ao atualizar produto no servidor (${res.statusCode})');
    }
  }
  
  Future<bool> deleteProduto(int serverId) async {
    final uri = Uri.parse('$baseUrl/produtos/$serverId');
    final res = await http.delete(uri);

    return res.statusCode == 200;
  }
}

class LocalDb {
  static final LocalDb _instance = LocalDb._internal();
  factory LocalDb() => _instance;
  LocalDb._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'catalogo_local.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE produtos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            server_id INTEGER,
            nome TEXT NOT NULL,
            preco REAL NOT NULL,
            descricao TEXT
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_produtos_server_id ON produtos(server_id)');
      },
    );
    return _db!;
  }

  Future<List<Produto>> getAll() async {
    final db = await database;
    final result = await db.query('produtos', orderBy: 'id DESC');
    return result.map((e) => Produto.fromLocalMap(e)).toList();
  }

  Future<int> insert(Produto p) async {
    final db = await database;
    return db.insert('produtos', p.toLocalMap()..remove('id'));
  }

  Future<int> update(Produto p) async {
    if (p.id == null) return 0;
    final db = await database;
    return db.update('produtos', p.toLocalMap()..remove('id'), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete('produtos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> upsertByServerId(List<Produto> serverProdutos) async {
    final db = await database;
    final batch = db.batch();

    for (final sp in serverProdutos) {
      if (sp.serverId == null) {
        batch.insert('produtos', sp.toLocalMap()..remove('id'));
        continue;
      }
      batch.update(
        'produtos',
        sp.toLocalMap()..remove('id'),
        where: 'server_id = ?',
        whereArgs: [sp.serverId],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      batch.insert(
        'produtos',
        sp.toLocalMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> syncBidirecional() async {
    final localProdutos = await getAll();
    
    try {
      final remoteService = RemoteService();
      final remoteProdutos = await remoteService.fetchProdutos();
      
      for (final localProduto in localProdutos) {
        if (localProduto.serverId != null) {
          bool existsOnServer = remoteProdutos.any((p) => p.serverId == localProduto.serverId);
          
          if (existsOnServer) {
            try {
              await remoteService.updateProduto(localProduto);
            } catch (e) {
              print('Erro ao atualizar produto no servidor: $e');
            }
          } else {
            try {
              final novoProdutoRemoto = await remoteService.addProduto(localProduto);
              await update(localProduto.copyWith(serverId: novoProdutoRemoto.serverId));
            } catch (e) {
              print('Erro ao adicionar produto no servidor: $e');
            }
          }
        } else {
          try {
            final novoProdutoRemoto = await remoteService.addProduto(localProduto);
            await update(localProduto.copyWith(serverId: novoProdutoRemoto.serverId));
          } catch (e) {
            print('Erro ao adicionar produto no servidor: $e');
          }
        }
      }
      
      for (final remotoProduto in remoteProdutos) {
        bool existsLocally = localProdutos.any((p) => p.serverId == remotoProduto.serverId);
        
        if (!existsLocally) {
          await insert(remotoProduto);
        }
      }
    } catch (e) {
      print('Erro na sincronização bidirecional: $e');
      rethrow;
    }
  }

  Future<void> updateFromServer(List<Produto> serverProdutos) async {
    await upsertByServerId(serverProdutos);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CatalogApp());
}

class CatalogApp extends StatelessWidget {
  const CatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catálogo de Produtos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF10B981)),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 3,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
          shape: CircleBorder(),
        ),
      ),
      home: const ProdutosScreen(),
    );
  }
}

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  final _local = LocalDb();

  List<Produto> _produtos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  Future<void> _initLoad() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final locais = await _local.getAll();
      setState(() => _produtos = locais);

      await _local.syncBidirecional();

      final atualizados = await _local.getAll();
      setState(() => _produtos = atualizados);
    } catch (e) {
      setState(() => _error = 'Falha ao sincronizar: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sync() async {
    try {
      await _local.syncBidirecional();
      
      final atualizados = await _local.getAll();
      setState(() => _produtos = atualizados);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sincronizado com o servidor!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao sincronizar: $e')),
        );
      }
    }
  }

  Future<void> _addOrEdit({Produto? editing}) async {
    final nomeCtrl = TextEditingController(text: editing?.nome ?? '');
    final precoCtrl = TextEditingController(
      text: editing != null ? editing.preco.toStringAsFixed(2) : '',
    );
    final descCtrl = TextEditingController(text: editing?.descricao ?? '');

    final isEdit = editing != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Editar Produto' : 'Novo Produto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
                textInputAction: TextInputAction.next,
              ),
              TextField(
                controller: precoCtrl,
                decoration: const InputDecoration(labelText: 'Preço'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
        ],
      ),
    );

    if (result != true) return;

    final nome = nomeCtrl.text.trim();
    final preco = double.tryParse(precoCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final desc = descCtrl.text.trim();

    if (nome.isEmpty) return;

    if (isEdit) {
      final updated = editing.copyWith(nome: nome, preco: preco, descricao: desc);
      await _local.update(updated);
    } else {
      await _local.insert(Produto(nome: nome, preco: preco, descricao: desc));
    }

    final recarregados = await _local.getAll();
    setState(() => _produtos = recarregados);
    
    try {
      await _sync();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produto salvo localmente, mas houve erro na sincronização: $e')),
        );
      }
    }
  }

  Future<void> _delete(Produto p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Produto'),
        content: Text('Deseja excluir "${p.nome}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirm != true) return;

    if (p.id != null) {
      await _local.delete(p.id!);
      
      if (p.serverId != null) {
        try {
          final remote = RemoteService();
          await remote.deleteProduto(p.serverId!);
        } catch (e) {
          print('Erro ao excluir no servidor: $e');
        }
      }
      
      final recarregados = await _local.getAll();
      setState(() => _produtos = recarregados);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('🛍️ Catálogo de Produtos'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Sincronizar com servidor',
              onPressed: _sync,
              icon: const Icon(Icons.sync_rounded),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sincronizando produtos...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Container(
                    margin: const EdgeInsets.all(24.0),
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red.shade600,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erro na sincronização',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _initLoad,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tentar novamente'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _produtos.isEmpty
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.inventory_2_rounded,
                                size: 64,
                                color: primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Catálogo vazio',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Adicione produtos ao seu catálogo\nou sincronize com o servidor!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _initLoad,
                      color: primary,
                      child: GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _produtos.length,
                        itemBuilder: (context, i) {
                          final p = _produtos[i];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header com preço
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.1),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'R\$ ${p.preco.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: primary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                
                                // Conteúdo
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.nome,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (p.descricao.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Expanded(
                                            child: Text(
                                              p.descricao,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                                height: 1.4,
                                              ),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                        
                                        // Botões de ação
                                        const Spacer(),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _addOrEdit(editing: p),
                                                icon: const Icon(Icons.edit_rounded, size: 16),
                                                label: const Text(
                                                  'Editar',
                                                  style: TextStyle(fontSize: 12),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: primary,
                                                  side: BorderSide(color: primary),
                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              onPressed: () => _delete(p),
                                              icon: const Icon(Icons.delete_outline_rounded),
                                              style: IconButton.styleFrom(
                                                foregroundColor: Colors.red.shade400,
                                                backgroundColor: Colors.red.shade50,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              tooltip: 'Excluir produto',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _addOrEdit,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text(
            'Novo Produto',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
