class FrequenciaDia {
  final int? id;
  final int alunoId;

  /// Dia do mês (1–31). Será clampado ao último dia do mês na geração.
  final int dia;
  final double valor;

  const FrequenciaDia({
    this.id,
    required this.alunoId,
    required this.dia,
    required this.valor,
  });

  FrequenciaDia copyWith({int? id, int? alunoId, int? dia, double? valor}) {
    return FrequenciaDia(
      id: id ?? this.id,
      alunoId: alunoId ?? this.alunoId,
      dia: dia ?? this.dia,
      valor: valor ?? this.valor,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'aluno_id': alunoId,
        'dia': dia,
        'valor': valor,
      };

  factory FrequenciaDia.fromMap(Map<String, dynamic> map) => FrequenciaDia(
        id: map['id'] as int?,
        alunoId: map['aluno_id'] as int,
        dia: map['dia'] as int,
        valor: (map['valor'] as num).toDouble(),
      );
}
