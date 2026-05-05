class Contrato {
  final int? id;
  final int alunoId;
  final DateTime dataInicio;
  final DateTime dataFim;

  const Contrato({
    this.id,
    required this.alunoId,
    required this.dataInicio,
    required this.dataFim,
  });

  Contrato copyWith({int? id, int? alunoId, DateTime? dataInicio, DateTime? dataFim}) {
    return Contrato(
      id: id ?? this.id,
      alunoId: alunoId ?? this.alunoId,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'aluno_id': alunoId,
        'data_inicio': dataInicio.toIso8601String().substring(0, 10),
        'data_fim': dataFim.toIso8601String().substring(0, 10),
      };

  factory Contrato.fromMap(Map<String, dynamic> map) => Contrato(
        id: map['id'] as int?,
        alunoId: map['aluno_id'] as int,
        dataInicio: DateTime.parse(map['data_inicio'] as String),
        dataFim: DateTime.parse(map['data_fim'] as String),
      );
}
