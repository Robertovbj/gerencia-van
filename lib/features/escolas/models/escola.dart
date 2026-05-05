class Escola {
  final int? id;
  final String nome;
  final bool ativo;

  const Escola({
    this.id,
    required this.nome,
    this.ativo = true,
  });

  Escola copyWith({int? id, String? nome, bool? ativo}) {
    return Escola(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      ativo: ativo ?? this.ativo,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'ativo': ativo ? 1 : 0,
      };

  factory Escola.fromMap(Map<String, dynamic> map) => Escola(
        id: map['id'] as int?,
        nome: map['nome'] as String,
        ativo: (map['ativo'] as int) == 1,
      );
}
