class Aluno {
  final int? id;
  final String nome;
  final String? apelido;
  final String? nomeResponsavel;
  final double valorMensalidade;
  final int escolaId;
  final String horario;
  final int diaPagamento;
  final bool ativo;

  // join field
  final String? escolaNome;

  const Aluno({
    this.id,
    required this.nome,
    this.apelido,
    this.nomeResponsavel,
    required this.valorMensalidade,
    required this.escolaId,
    this.horario = 'manha',
    this.diaPagamento = 1,
    this.ativo = true,
    this.escolaNome,
  });

  Aluno copyWith({
    int? id,
    String? nome,
    String? apelido,
    String? nomeResponsavel,
    double? valorMensalidade,
    int? escolaId,
    String? horario,
    int? diaPagamento,
    bool? ativo,
    String? escolaNome,
  }) {
    return Aluno(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      apelido: apelido ?? this.apelido,
      nomeResponsavel: nomeResponsavel ?? this.nomeResponsavel,
      valorMensalidade: valorMensalidade ?? this.valorMensalidade,
      escolaId: escolaId ?? this.escolaId,
      horario: horario ?? this.horario,
      diaPagamento: diaPagamento ?? this.diaPagamento,
      ativo: ativo ?? this.ativo,
      escolaNome: escolaNome ?? this.escolaNome,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'apelido': apelido,
        'nome_responsavel': nomeResponsavel,
        'valor_mensalidade': valorMensalidade,
        'escola_id': escolaId,
        'horario': horario,
        'dia_pagamento': diaPagamento,
        'ativo': ativo ? 1 : 0,
      };

  factory Aluno.fromMap(Map<String, dynamic> map) => Aluno(
        id: map['id'] as int?,
        nome: map['nome'] as String,
        apelido: map['apelido'] as String?,
        nomeResponsavel: map['nome_responsavel'] as String?,
        valorMensalidade: (map['valor_mensalidade'] as num).toDouble(),
        escolaId: map['escola_id'] as int,
        horario: map['horario'] as String? ?? 'manha',
        diaPagamento: map['dia_pagamento'] as int? ?? 1,
        ativo: (map['ativo'] as int) == 1,
        escolaNome: map['escola_nome'] as String?,
      );

  String get nomeExibicao =>
      apelido != null && apelido!.isNotEmpty ? '$nome (${apelido!})' : nome;
}
