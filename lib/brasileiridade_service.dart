import 'dart:convert';
import 'package:http/http.dart' as http;

/// Serviço para análise de brasileiridade de marcas
/// Baseado no sistema de análise do grau de brasileiridade (0-100%)
class BrasileiridadeService {
  static const String _userAgent = 'CompreBrasil/1.0 (vrpedrinho@gmail.com)';
  static const int _timeout = 8000; // 8 segundos

  /// Resultado da análise de brasileiridade
  static Future<AnaliseResult> analisarBrasileiridade(String marca) async {
    final marcaNormalizada = _normalizarMarca(marca);
    final variacoes = _gerarVariacoesMarca(marcaNormalizada);

    print('🔍 Analisando brasileiridade de "$marca"');
    print('Testando ${variacoes.length} variações: ${variacoes.join(', ')}');

    final analise = AnaliseResult(
      marca: marca,
      origem: null,
      fabricacao: null,
      propriedadeLocal: null,
      propriedadeMatriz: null,
      cadeiaProprietaria: [],
      grauBrasileiridade: 0,
      classificacao: '',
      detalhes: [],
    );

    // 1. Buscar cadeia proprietária completa (PRIORIDADE ALTA)
    for (final variacao in variacoes) {
      final cadeia = await _buscarCadeiaProprietaria(variacao);
      if (cadeia.isNotEmpty) {
        analise.cadeiaProprietaria = cadeia;
        analise.propriedadeLocal = cadeia.first;
        analise.propriedadeMatriz = cadeia.last;
        print('✓ Cadeia proprietária: ${cadeia.join(' → ')}');
        break;
      }
    }

    // 2. Buscar fabricação/sede (PRIORIDADE MÉDIA)
    for (final variacao in variacoes) {
      final fabricacao = await _buscarFabricacao(variacao);
      if (fabricacao != null) {
        analise.fabricacao = fabricacao;
        print('✓ Fabricação/Sede: $fabricacao');
        break;
      }
    }

    // 3. Buscar origem da marca (PRIORIDADE BAIXA)
    for (final variacao in variacoes) {
      final origem = await _buscarOrigemMarca(variacao);
      if (origem != null) {
        analise.origem = origem;
        print('✓ Origem encontrada: $origem');
        break;
      }
    }

    // 4. Verificar se há dados suficientes
    final temDados =
        analise.origem != null ||
        analise.fabricacao != null ||
        analise.propriedadeLocal != null ||
        analise.propriedadeMatriz != null ||
        analise.cadeiaProprietaria.isNotEmpty;

    if (!temDados) {
      analise.semDados = true;
      analise.grauBrasileiridade = null;
      analise.classificacao = '❓ Análise não foi possível';
      analise.detalhes = ['Dados insuficientes no Wikidata'];
      return analise;
    }

    // 5. Calcular grau de brasileiridade
    analise.grauBrasileiridade = _calcularGrauBrasileiridade(analise);
    analise.classificacao = _classificarBrasileiridade(analise.grauBrasileiridade!);
    analise.detalhes = _gerarDetalhesAnalise(analise);

    return analise;
  }

  /// Analisa múltiplas marcas separadas por vírgula e retorna a mais brasileira
  static Future<AnaliseResult> analisarMultiplasMarcas(String marcasString) async {
    // Separa as marcas por vírgula e limpa espaços
    final marcas = marcasString
        .split(',')
        .map((marca) => marca.trim())
        .where((marca) => marca.isNotEmpty)
        .toList();

    if (marcas.isEmpty) {
      return AnaliseResult(
        marca: marcasString,
        origem: null,
        fabricacao: null,
        propriedadeLocal: null,
        propriedadeMatriz: null,
        cadeiaProprietaria: [],
        grauBrasileiridade: null,
        classificacao: '❓ Nenhuma marca válida encontrada',
        detalhes: ['Entrada inválida'],
        semDados: true,
      );
    }

    // Se há apenas uma marca, analisa normalmente
    if (marcas.length == 1) {
      return await analisarBrasileiridade(marcas.first);
    }

    print('🔍 MODO COMPARATIVO: Analisando ${marcas.length} marcas');
    print('Marcas: ${marcas.join(', ')}');

    final resultados = <AnaliseResult>[];

    // Analisa cada marca individualmente
    for (int i = 0; i < marcas.length; i++) {
      final marca = marcas[i];
      print('\n📍 [${i + 1}/${marcas.length}] Analisando "$marca"');

      try {
        final analise = await analisarBrasileiridade(marca);
        resultados.add(analise);

        // Log do resultado
        if (analise.semDados) {
          print('   Status: ${analise.classificacao}');
        } else {
          print('   Brasileiridade: ${analise.grauBrasileiridade}% - ${analise.classificacao}');
        }
      } catch (error) {
        print('   ❌ Erro ao analisar "$marca": $error');
        resultados.add(
          AnaliseResult(
            marca: marca,
            origem: null,
            fabricacao: null,
            propriedadeLocal: null,
            propriedadeMatriz: null,
            cadeiaProprietaria: [],
            grauBrasileiridade: null,
            classificacao: '❌ Erro na análise',
            detalhes: ['Erro: $error'],
            semDados: true,
          ),
        );
      }
    }

    // Encontra a marca mais brasileira
    final marcasValidas = resultados
        .where((r) => !r.semDados && r.grauBrasileiridade != null)
        .toList();

    if (marcasValidas.isEmpty) {
      print('\n❌ Nenhuma marca válida encontrada');
      return AnaliseResult(
        marca: marcasString,
        origem: null,
        fabricacao: null,
        propriedadeLocal: null,
        propriedadeMatriz: null,
        cadeiaProprietaria: [],
        grauBrasileiridade: null,
        classificacao: '❌ Dados insuficientes para todas as marcas',
        detalhes: ['Nenhuma das marcas teve dados suficientes para análise'],
        semDados: true,
      );
    }

    // Encontra a marca com maior grau de brasileiridade
    final marcaMaisBrasileira = marcasValidas.reduce(
      (prev, atual) => atual.grauBrasileiridade! > prev.grauBrasileiridade! ? atual : prev,
    );

    print('\n🏆 MARCA MAIS BRASILEIRA: ${marcaMaisBrasileira.marca}');
    print('Grau: ${marcaMaisBrasileira.grauBrasileiridade}%');
    print('Classificação: ${marcaMaisBrasileira.classificacao}');

    // Adiciona informações sobre a comparação nos detalhes
    final detalhesComparacao = List<String>.from(marcaMaisBrasileira.detalhes);
    detalhesComparacao.insert(0, 'Marca selecionada entre: ${marcas.join(', ')}');

    // Adiciona resumo das outras marcas
    for (final resultado in resultados) {
      if (resultado.marca != marcaMaisBrasileira.marca) {
        final grau = resultado.grauBrasileiridade ?? 0;
        detalhesComparacao.add('${resultado.marca}: ${grau}% - ${resultado.classificacao}');
      }
    }

    return AnaliseResult(
      marca: marcaMaisBrasileira.marca,
      origem: marcaMaisBrasileira.origem,
      fabricacao: marcaMaisBrasileira.fabricacao,
      propriedadeLocal: marcaMaisBrasileira.propriedadeLocal,
      propriedadeMatriz: marcaMaisBrasileira.propriedadeMatriz,
      cadeiaProprietaria: marcaMaisBrasileira.cadeiaProprietaria,
      grauBrasileiridade: marcaMaisBrasileira.grauBrasileiridade,
      classificacao: marcaMaisBrasileira.classificacao,
      detalhes: detalhesComparacao,
      semDados: false,
    );
  }

  /// Faz requisição HTTP com retry
  static Future<http.Response?> _fetchComRetry(String url, {int maxRetries = 2}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final response = await http
            .get(Uri.parse(url), headers: {'User-Agent': _userAgent})
            .timeout(Duration(milliseconds: _timeout));

        if (response.statusCode == 200) {
          return response;
        } else if (response.statusCode >= 500 && i < maxRetries - 1) {
          print(
            'Servidor ocupado (${response.statusCode}), tentando novamente... (${i + 1}/$maxRetries)',
          );
          await Future.delayed(Duration(seconds: 1));
          continue;
        } else {
          throw Exception('HTTP ${response.statusCode}');
        }
      } catch (err) {
        if (i == maxRetries - 1) {
          print('Erro na requisição: $err');
          return null;
        }
        print('Erro na tentativa ${i + 1}: ${err.toString().substring(0, 50)}...');
        await Future.delayed(Duration(seconds: 1));
      }
    }
    return null;
  }

  /// Normaliza a marca
  static String _normalizarMarca(String marca) {
    return marca
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(
          RegExp(
            r'[""'
            ']',
          ),
          '"',
        )
        .replaceAll(RegExp(r'[–—]'), '-');
  }

  /// Gera variações da marca
  static List<String> _gerarVariacoesMarca(String marca) {
    final variacoes = <String>{};

    variacoes.add(marca);
    variacoes.add(marca.toLowerCase());
    variacoes.add(marca.toUpperCase());
    variacoes.add(_capitalize(marca));
    variacoes.add(_titleCase(marca));

    return variacoes.toList();
  }

  /// Capitaliza primeira letra
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Title case
  static String _titleCase(String text) {
    return text.split(' ').map((word) => _capitalize(word)).join(' ');
  }

  /// Busca origem da marca
  static Future<String?> _buscarOrigemMarca(String marca) async {
    final query =
        '''
      SELECT ?paisLabel WHERE {
        ?m rdfs:label "$marca"@pt .
        {
          ?m wdt:P495 ?pais .
        }
        UNION
        {
          ?m wdt:P17 ?pais .
        }
        SERVICE wikibase:label {
          bd:serviceParam wikibase:language "pt,en" .
          ?pais rdfs:label ?paisLabel .
        }
      }
      LIMIT 1
    ''';

    try {
      final url =
          'https://query.wikidata.org/sparql?format=json&query=${Uri.encodeComponent(query)}';
      final response = await _fetchComRetry(url);

      if (response != null) {
        final data = json.decode(response.body);
        if (data['results']['bindings'].isNotEmpty) {
          return data['results']['bindings'][0]['paisLabel']['value'];
        }
      }

      // Tenta em inglês
      final queryEn = query.replaceAll('@pt', '@en');
      final urlEn =
          'https://query.wikidata.org/sparql?format=json&query=${Uri.encodeComponent(queryEn)}';
      final responseEn = await _fetchComRetry(urlEn);

      if (responseEn != null) {
        final dataEn = json.decode(responseEn.body);
        if (dataEn['results']['bindings'].isNotEmpty) {
          return dataEn['results']['bindings'][0]['paisLabel']['value'];
        }
      }

      return null;
    } catch (err) {
      return null;
    }
  }

  /// Busca fabricação/sede
  static Future<String?> _buscarFabricacao(String marca) async {
    final query =
        '''
      SELECT ?paisLabel WHERE {
        ?m rdfs:label "$marca"@pt .
        {
          ?m wdt:P159 ?local .
          ?local wdt:P17 ?pais .
        }
        UNION
        {
          ?m wdt:P176 ?fabricante .
          ?fabricante wdt:P159 ?local .
          ?local wdt:P17 ?pais .
        }
        SERVICE wikibase:label {
          bd:serviceParam wikibase:language "pt,en" .
          ?pais rdfs:label ?paisLabel .
        }
      }
      LIMIT 1
    ''';

    try {
      final url =
          'https://query.wikidata.org/sparql?format=json&query=${Uri.encodeComponent(query)}';
      final response = await _fetchComRetry(url);

      if (response != null) {
        final data = json.decode(response.body);
        if (data['results']['bindings'].isNotEmpty) {
          return data['results']['bindings'][0]['paisLabel']['value'];
        }
      }

      // Tenta em inglês
      final queryEn = query.replaceAll('@pt', '@en');
      final urlEn =
          'https://query.wikidata.org/sparql?format=json&query=${Uri.encodeComponent(queryEn)}';
      final responseEn = await _fetchComRetry(urlEn);

      if (responseEn != null) {
        final dataEn = json.decode(responseEn.body);
        if (dataEn['results']['bindings'].isNotEmpty) {
          return dataEn['results']['bindings'][0]['paisLabel']['value'];
        }
      }

      return null;
    } catch (err) {
      return null;
    }
  }

  /// Busca cadeia proprietária
  static Future<List<String>> _buscarCadeiaProprietaria(String marca) async {
    final query =
        '''
      SELECT ?proprietario1Label ?pais1Label ?proprietario2Label ?pais2Label ?proprietario3Label ?pais3Label WHERE {
        ?m rdfs:label "$marca"@pt .
        
        OPTIONAL {
          {
            ?m wdt:P127 ?proprietario1 .
          }
          UNION
          {
            ?m wdt:P749 ?proprietario1 .
          }
          UNION
          {
            ?m wdt:P176 ?proprietario1 .
          }
          ?proprietario1 wdt:P17 ?pais1 .
          
          OPTIONAL {
            {
              ?proprietario1 wdt:P127 ?proprietario2 .
            }
            UNION
            {
              ?proprietario1 wdt:P749 ?proprietario2 .
            }
            ?proprietario2 wdt:P17 ?pais2 .
            
            OPTIONAL {
              {
                ?proprietario2 wdt:P127 ?proprietario3 .
              }
              UNION
              {
                ?proprietario2 wdt:P749 ?proprietario3 .
              }
              ?proprietario3 wdt:P17 ?pais3 .
            }
          }
        }
        
        SERVICE wikibase:label {
          bd:serviceParam wikibase:language "pt,en" .
          ?proprietario1 rdfs:label ?proprietario1Label .
          ?pais1 rdfs:label ?pais1Label .
          ?proprietario2 rdfs:label ?proprietario2Label .
          ?pais2 rdfs:label ?pais2Label .
          ?proprietario3 rdfs:label ?proprietario3Label .
          ?pais3 rdfs:label ?pais3Label .
        }
      }
      LIMIT 1
    ''';

    try {
      final url =
          'https://query.wikidata.org/sparql?format=json&query=${Uri.encodeComponent(query)}';
      final response = await _fetchComRetry(url);

      if (response != null) {
        final data = json.decode(response.body);
        if (data['results']['bindings'].isNotEmpty) {
          final binding = data['results']['bindings'][0];
          final cadeia = <String>[];

          if (binding['proprietario1Label'] != null) {
            final pais1 = binding['pais1Label']?['value'] ?? 'País desconhecido';
            cadeia.add('${binding['proprietario1Label']['value']} ($pais1)');
          }
          if (binding['proprietario2Label'] != null) {
            final pais2 = binding['pais2Label']?['value'] ?? 'País desconhecido';
            cadeia.add('${binding['proprietario2Label']['value']} ($pais2)');
          }
          if (binding['proprietario3Label'] != null) {
            final pais3 = binding['pais3Label']?['value'] ?? 'País desconhecido';
            cadeia.add('${binding['proprietario3Label']['value']} ($pais3)');
          }

          return cadeia;
        }
      }

      // Tenta em inglês
      final queryEn = query.replaceAll('@pt', '@en');
      final urlEn =
          'https://query.wikidata.org/sparql?format=json&query=${Uri.encodeComponent(queryEn)}';
      final responseEn = await _fetchComRetry(urlEn);

      if (responseEn != null) {
        final dataEn = json.decode(responseEn.body);
        if (dataEn['results']['bindings'].isNotEmpty) {
          final binding = dataEn['results']['bindings'][0];
          final cadeia = <String>[];

          if (binding['proprietario1Label'] != null) {
            final pais1 = binding['pais1Label']?['value'] ?? 'País desconhecido';
            cadeia.add('${binding['proprietario1Label']['value']} ($pais1)');
          }
          if (binding['proprietario2Label'] != null) {
            final pais2 = binding['pais2Label']?['value'] ?? 'País desconhecido';
            cadeia.add('${binding['proprietario2Label']['value']} ($pais2)');
          }
          if (binding['proprietario3Label'] != null) {
            final pais3 = binding['pais3Label']?['value'] ?? 'País desconhecido';
            cadeia.add('${binding['proprietario3Label']['value']} ($pais3)');
          }

          return cadeia;
        }
      }

      return [];
    } catch (err) {
      return [];
    }
  }

  /// Calcula grau de brasileiridade
  static int _calcularGrauBrasileiridade(AnaliseResult analise) {
    int pontos = 0;
    int maxPontos = 0;

    // Pesos inteligentes
    const pesos = {'propriedadeMatriz': 40, 'propriedadeLocal': 30, 'fabricacao': 20, 'origem': 10};

    // Propriedade Matriz (40 pontos)
    maxPontos += pesos['propriedadeMatriz']!;
    if (analise.propriedadeMatriz != null && analise.propriedadeMatriz!.contains('Brasil')) {
      pontos += pesos['propriedadeMatriz']!;
    }

    // Propriedade Local (30 pontos)
    maxPontos += pesos['propriedadeLocal']!;
    if (analise.propriedadeLocal != null && analise.propriedadeLocal!.contains('Brasil')) {
      pontos += pesos['propriedadeLocal']!;
    }

    // Fabricação/Sede (20 pontos)
    maxPontos += pesos['fabricacao']!;
    if (analise.fabricacao == 'Brasil') {
      pontos += pesos['fabricacao']!;
    }

    // Origem (10 pontos)
    maxPontos += pesos['origem']!;
    if (analise.origem == 'Brasil') {
      pontos += pesos['origem']!;
    }

    // Bônus para cadeias proprietárias totalmente brasileiras
    if (analise.cadeiaProprietaria.isNotEmpty) {
      final todasBrasileiras = analise.cadeiaProprietaria.every(
        (empresa) => empresa.contains('Brasil'),
      );
      if (todasBrasileiras) {
        pontos += 5;
        maxPontos += 5;
      }
    }

    return ((pontos / maxPontos) * 100).round();
  }

  /// Classifica brasileiridade
  static String _classificarBrasileiridade(int grau) {
    if (grau >= 85) return '🇧🇷 Totalmente Brasileira';
    if (grau >= 65) return '🟢 Majoritariamente Brasileira';
    if (grau >= 45) return '🟡 Parcialmente Brasileira';
    if (grau >= 25) return '🟠 Pouco Brasileira';
    if (grau > 0) return '🔴 Minimamente Brasileira';
    return '🌍 Marca Estrangeira';
  }

  /// Gera detalhes da análise
  static List<String> _gerarDetalhesAnalise(AnaliseResult analise) {
    final detalhes = <String>[];

    if (analise.origem != null) {
      detalhes.add('Origem: ${analise.origem}');
    }
    if (analise.fabricacao != null) {
      detalhes.add('Fabricação/Sede: ${analise.fabricacao}');
    }
    if (analise.cadeiaProprietaria.isNotEmpty) {
      detalhes.add('Cadeia proprietária: ${analise.cadeiaProprietaria.join(' → ')}');
    }

    return detalhes;
  }
}

/// Classe que representa o resultado da análise
class AnaliseResult {
  final String marca;
  String? origem;
  String? fabricacao;
  String? propriedadeLocal;
  String? propriedadeMatriz;
  List<String> cadeiaProprietaria;
  int? grauBrasileiridade;
  String classificacao;
  List<String> detalhes;
  bool semDados;

  AnaliseResult({
    required this.marca,
    this.origem,
    this.fabricacao,
    this.propriedadeLocal,
    this.propriedadeMatriz,
    required this.cadeiaProprietaria,
    required this.grauBrasileiridade,
    required this.classificacao,
    required this.detalhes,
    this.semDados = false,
  });

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'marca': marca,
      'origem': origem,
      'fabricacao': fabricacao,
      'propriedadeLocal': propriedadeLocal,
      'propriedadeMatriz': propriedadeMatriz,
      'cadeiaProprietaria': cadeiaProprietaria,
      'grauBrasileiridade': grauBrasileiridade,
      'classificacao': classificacao,
      'detalhes': detalhes,
      'semDados': semDados,
    };
  }

  /// Cria instância a partir de JSON
  factory AnaliseResult.fromJson(Map<String, dynamic> json) {
    return AnaliseResult(
      marca: json['marca'],
      origem: json['origem'],
      fabricacao: json['fabricacao'],
      propriedadeLocal: json['propriedadeLocal'],
      propriedadeMatriz: json['propriedadeMatriz'],
      cadeiaProprietaria: List<String>.from(json['cadeiaProprietaria'] ?? []),
      grauBrasileiridade: json['grauBrasileiridade'],
      classificacao: json['classificacao'],
      detalhes: List<String>.from(json['detalhes'] ?? []),
      semDados: json['semDados'] ?? false,
    );
  }
}
