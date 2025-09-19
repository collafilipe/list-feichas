class Article {
  final int id;
  final String titulo;
  final String conteudo;
  final String autor;

  Article({
    required this.id,
    required this.titulo,
    required this.conteudo,
    required this.autor,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'],
      titulo: json['titulo'],
      conteudo: json['conteudo'],
      autor: json['autor'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'conteudo': conteudo,
      'autor': autor,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'conteudo': conteudo,
      'autor': autor,
    };
  }

  factory Article.fromMap(Map<String, dynamic> map) {
    return Article(
      id: map['id'],
      titulo: map['titulo'],
      conteudo: map['conteudo'],
      autor: map['autor'],
    );
  }

  @override
  String toString() {
    return 'Article{id: $id, titulo: $titulo, autor: $autor}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Article && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}