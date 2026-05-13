class Pagamento {
  final int? id;
  final int alunoId;
  final int contratoId;
  final String mesReferencia;

  /// Data de vencimento específica para cobranças personalizadas (nullable para mensal).
  final DateTime? dataVencimento;
  final double valorPrevisto;
  final double? valorPago;
  final bool pago;
  final DateTime? dataPagamento;

  // join fields
  final String? alunoNome;
  final String? alunoApelido;
  final String? escolaNome;
  final String? horario;
  final int? diaPagamento;

  const Pagamento({
    this.id,
    required this.alunoId,
    required this.contratoId,
    required this.mesReferencia,
    this.dataVencimento,
    required this.valorPrevisto,
    this.valorPago,
    this.pago = false,
    this.dataPagamento,
    this.alunoNome,
    this.alunoApelido,
    this.escolaNome,
    this.horario,
    this.diaPagamento,
  });

  Pagamento copyWith({
    int? id,
    int? alunoId,
    int? contratoId,
    String? mesReferencia,
    DateTime? dataVencimento,
    double? valorPrevisto,
    double? valorPago,
    bool? pago,
    DateTime? dataPagamento,
    bool clearDataPagamento = false,
    bool clearValorPago = false,
  }) {
    return Pagamento(
      id: id ?? this.id,
      alunoId: alunoId ?? this.alunoId,
      contratoId: contratoId ?? this.contratoId,
      mesReferencia: mesReferencia ?? this.mesReferencia,
      dataVencimento: dataVencimento ?? this.dataVencimento,
      valorPrevisto: valorPrevisto ?? this.valorPrevisto,
      valorPago: clearValorPago ? null : (valorPago ?? this.valorPago),
      pago: pago ?? this.pago,
      dataPagamento: clearDataPagamento ? null : (dataPagamento ?? this.dataPagamento),
      alunoNome: alunoNome,
      alunoApelido: alunoApelido,
      escolaNome: escolaNome,
      horario: horario,
      diaPagamento: diaPagamento,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'aluno_id': alunoId,
        'contrato_id': contratoId,
        'mes_referencia': mesReferencia,
        'data_vencimento': dataVencimento?.toIso8601String().substring(0, 10),
        'valor_previsto': valorPrevisto,
        'valor_pago': valorPago,
        'pago': pago ? 1 : 0,
        'data_pagamento': dataPagamento?.toIso8601String().substring(0, 10),
      };

  factory Pagamento.fromMap(Map<String, dynamic> map) => Pagamento(
        id: map['id'] as int?,
        alunoId: map['aluno_id'] as int,
        contratoId: map['contrato_id'] as int,
        mesReferencia: map['mes_referencia'] as String,
        dataVencimento: map['data_vencimento'] != null
            ? DateTime.parse(map['data_vencimento'] as String)
            : null,
        valorPrevisto: (map['valor_previsto'] as num).toDouble(),
        valorPago: map['valor_pago'] != null ? (map['valor_pago'] as num).toDouble() : null,
        pago: (map['pago'] as int) == 1,
        dataPagamento: map['data_pagamento'] != null
            ? DateTime.parse(map['data_pagamento'] as String)
            : null,
        alunoNome: map['aluno_nome'] as String?,
        alunoApelido: map['aluno_apelido'] as String?,
        escolaNome: map['escola_nome'] as String?,
        horario: map['horario'] as String?,
        diaPagamento: map['dia_pagamento'] as int?,
      );

  String get nomeExibicao =>
      alunoApelido != null && alunoApelido!.isNotEmpty
          ? '${alunoNome ?? ''} ($alunoApelido)'
          : (alunoNome ?? '');
}
