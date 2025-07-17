import 'dart:convert';
import 'package:http/http.dart' as http;

/// SERVIÇO DE ANÁLISE DE BRASILEIRIDADE DE MARCAS
///
/// Este serviço realiza análise completa da brasileiridade de marcas comerciais,
/// calculando um grau de 0-100% baseado em múltiplos critérios ponderados:
///
/// FONTES DE DADOS:
/// • Wikidata: Cadeia proprietária, origem, fabricação e sede das marcas
/// • OpenFoodFacts: Dados de fabricação, origem de ingredientes e localização
///
/// ALGORITMO DE CÁLCULO:
/// • Propriedade Matriz (40 pontos): Empresa controladora final
/// • Propriedade Local (30 pontos): Empresa proprietária direta
/// • Fabricação/Sede (20 pontos): Local de produção ou sede
/// • Origem da Marca (10 pontos): País de origem histórica
/// • Bônus Cadeia Brasileira (5 pontos): Toda cadeia proprietária no Brasil
/// • Bônus OpenFoodFacts (até 70 pontos): Dados de fabricação e origem
///
/// CLASSIFICAÇÃO FINAL:5
/// • 85-100%: 🇧🇷 Totalmente Brasileira
/// • 65-84%: 🟢 Majoritariamente Brasileira
/// • 45-64%: 🟡 Parcialmente Brasileira
/// • 25-44%: 🟠 Pouco Brasileira
/// • 1-24%: 🔴 Minimamente Brasileira
/// • 0%: 🌍 Marca Estrangeira
class BrasileiridadeService {
  // ==========================================================================
  // CONFIGURAÇÕES E CONSTANTES
  // ==========================================================================

  /// User-Agent para identificação nas requisições HTTP
  static const String _userAgent = 'CompreBrasil/1.0 (vrpedrinho@gmail.com)';

  /// Timeout para requisições HTTP (8 segundos)
  static const int _timeout = 8000;

  // ==========================================================================
  // FUNÇÃO PRINCIPAL DE ANÁLISE
  // ==========================================================================

  /// Analisa a brasileiridade de uma marca individual
  ///
  /// PROCESSO DE ANÁLISE:
  /// 1. Normalização e geração de variações da marca
  /// 2. Busca de dados no Wikidata (cadeia proprietária, fabricação, origem)
  /// 3. Verificação de suficiência de dados
  /// 4. Cálculo do grau de brasileiridade
  /// 5. Classificação e geração de detalhes
  ///
  /// @param marca Nome da marca a ser analisada
  /// @return AnaliseResult com grau de brasileiridade e detalhes
  static Future<AnaliseResult> analisarBrasileiridade(String marca) async {
    // Verifica se é um produto FAKE para teste - isolamento completo
    if (marca.contains('FAKE') ||
        marca.contains('Marca Brasileira LTDA') ||
        marca.contains('Empresa Majoritariamente Brasileira') ||
        marca.contains('Empresa Parcialmente Brasileira') ||
        marca.contains('Empresa Pouco Brasileira') ||
        marca.contains('Empresa Minimamente Brasileira') ||
        marca.contains('Marca Estrangeira Internacional') ||
        marca.contains('American Corporation')) {
      print('🔍 Produto FAKE detectado - usando dados isolados: "$marca"');
      return _getFakeAnalysisResult(marca);
    }

    // ETAPA 1: Preparação dos dados de entrada
    final marcaNormalizada = _normalizarMarca(marca);
    final variacoes = _gerarVariacoesMarca(marcaNormalizada);

    print('🔍 Analisando brasileiridade de "$marca"');
    print('Testando ${variacoes.length} variações: ${variacoes.join(', ')}');

    // ETAPA 2: Inicialização do resultado da análise
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

    // ETAPA 3: Busca de dados no Wikidata (ordem de prioridade)

    // 3.1. Buscar cadeia proprietária completa (PRIORIDADE ALTA)
    // A cadeia proprietária é o critério mais importante pois determina
    // o controle real da marca
    for (final variacao in variacoes) {
      final cadeia = await _buscarCadeiaProprietaria(variacao);
      if (cadeia.isNotEmpty) {
        analise.cadeiaProprietaria = cadeia;
        analise.propriedadeLocal = cadeia.first; // Proprietário direto
        analise.propriedadeMatriz = cadeia.last; // Proprietário final
        print('✓ Cadeia proprietária: ${cadeia.join(' → ')}');
        break;
      }
    }

    // 3.2. Buscar fabricação/sede (PRIORIDADE MÉDIA)
    // Local de produção ou sede principal da empresa
    for (final variacao in variacoes) {
      final fabricacao = await _buscarFabricacao(variacao);
      if (fabricacao != null) {
        analise.fabricacao = fabricacao;
        print('✓ Fabricação/Sede: $fabricacao');
        break;
      }
    }

    // 3.3. Buscar origem da marca (PRIORIDADE BAIXA)
    // País onde a marca foi criada/fundada originalmente
    for (final variacao in variacoes) {
      final origem = await _buscarOrigemMarca(variacao);
      if (origem != null) {
        analise.origem = origem;
        print('✓ Origem encontrada: $origem');
        break;
      }
    }

    // ETAPA 4: Verificação de suficiência de dados
    // Pelo menos um critério deve ter dados para prosseguir
    final temDados =
        analise.origem != null ||
        analise.fabricacao != null ||
        analise.propriedadeLocal != null ||
        analise.propriedadeMatriz != null ||
        analise.cadeiaProprietaria.isNotEmpty;

    if (!temDados) {
      // Retorna resultado indicando dados insuficientes
      analise.semDados = true;
      analise.grauBrasileiridade = null;
      analise.classificacao = '❓ Análise não foi possível';
      analise.detalhes = ['Dados insuficientes no Wikidata'];
      return analise;
    }

    // ETAPA 5: Cálculo final da brasileiridade
    analise.grauBrasileiridade = _calcularGrauBrasileiridade(analise);
    analise.classificacao = _classificarBrasileiridade(analise.grauBrasileiridade!);
    analise.detalhes = _gerarDetalhesAnalise(analise);

    return analise;
  }

  // ==========================================================================
  // ANÁLISE DE MÚLTIPLAS MARCAS
  // ==========================================================================

  /// Analisa múltiplas marcas e retorna a com maior grau de brasileiridade
  ///
  /// PROCESSO:
  /// 1. Separação das marcas por vírgula
  /// 2. Análise individual de cada marca
  /// 3. Comparação dos graus de brasileiridade
  /// 4. Retorno da marca mais brasileira com detalhes comparativos
  ///
  /// @param marcasString String com marcas separadas por vírgula (ex: "nestlé,nescau")
  /// @return AnaliseResult da marca mais brasileira
  static Future<AnaliseResult> analisarMultiplasMarcas(String marcasString) async {
    // ETAPA 1: Preparação dos dados de entrada
    final marcas = marcasString
        .split(',')
        .map((marca) => marca.trim())
        .where((marca) => marca.isNotEmpty)
        .toList();

    // Validação de entrada
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

    // ETAPA 2: Análise comparativa
    print('🔍 MODO COMPARATIVO: Analisando ${marcas.length} marcas');
    print('Marcas: ${marcas.join(', ')}');

    final resultados = <AnaliseResult>[];

    // 2.1. Análise individual de cada marca
    for (int i = 0; i < marcas.length; i++) {
      final marca = marcas[i];
      print('\n📍 [${i + 1}/${marcas.length}] Analisando "$marca"');

      try {
        final analise = await analisarBrasileiridade(marca);
        resultados.add(analise);

        // Log do resultado para acompanhamento
        if (analise.semDados) {
          print('   Status: ${analise.classificacao}');
        } else {
          print('   Brasileiridade: ${analise.grauBrasileiridade}% - ${analise.classificacao}');
        }
      } catch (error) {
        print('   ❌ Erro ao analisar "$marca": $error');
        // Adiciona resultado de erro para não interromper o processo
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

    // ETAPA 3: Seleção da marca mais brasileira
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

    // 3.1. Encontra a marca com maior grau de brasileiridade
    final marcaMaisBrasileira = marcasValidas.reduce(
      (prev, atual) => atual.grauBrasileiridade! > prev.grauBrasileiridade! ? atual : prev,
    );

    print('\n🏆 MARCA MAIS BRASILEIRA: ${marcaMaisBrasileira.marca}');
    print('Grau: ${marcaMaisBrasileira.grauBrasileiridade}%');
    print('Classificação: ${marcaMaisBrasileira.classificacao}');

    // ETAPA 4: Geração de detalhes comparativos
    final detalhesComparacao = List<String>.from(marcaMaisBrasileira.detalhes);
    detalhesComparacao.insert(0, 'Marca selecionada entre: ${marcas.join(', ')}');

    // Adiciona resumo das outras marcas para comparação
    for (final resultado in resultados) {
      if (resultado.marca != marcaMaisBrasileira.marca) {
        final grau = resultado.grauBrasileiridade ?? 0;
        detalhesComparacao.add('${resultado.marca}: ${grau}% - ${resultado.classificacao}');
      }
    }

    // Retorna a marca mais brasileira com detalhes comparativos
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

  // ==========================================================================
  // INTEGRAÇÃO COM OPENFOODFACTS
  // ==========================================================================

  /// Complementa análise Wikidata com dados do OpenFoodFacts
  ///
  /// DADOS ANALISADOS:
  /// • manufacturing_places: Local de fabricação (15 pontos)
  /// • origins: Origem dos ingredientes (10 pontos)
  /// • countries_tags: Tags de países (20 pontos)
  /// • made_in: Indicação de fabricação (25 pontos)
  ///
  /// BÔNUS TOTAL: Até 70 pontos adicionais
  ///
  /// @param productData Dados do produto do OpenFoodFacts
  /// @param analiseExistente Análise prévia do Wikidata
  /// @return AnaliseResult atualizada com dados do OpenFoodFacts
  static AnaliseResult analisarDadosOpenFoodFacts(
    Map<String, dynamic> productData,
    AnaliseResult analiseExistente,
  ) {
    print('🔍 Analisando dados OpenFoodFacts para brasileiridade');
    print('📊 Marca: ${analiseExistente.marca}');
    print('📊 Grau atual: ${analiseExistente.grauBrasileiridade}%');
    print('📊 Classificação atual: ${analiseExistente.classificacao}');

    final product = productData['product'];
    if (product == null) {
      print('⚠️ Produto não encontrado nos dados OpenFoodFacts');
      return analiseExistente;
    }

    // ETAPA 1: Extração de dados do OpenFoodFacts
    final manufacturingPlaces = product['manufacturing_places']?.toString();
    final origins = product['origins']?.toString();
    final countriesTags = product['countries_tags']?.cast<String>() ?? <String>[];
    final madeIn = product['made_in']?.toString();

    // ETAPA 2: Análise de brasileiridade nos dados OpenFoodFacts
    int bonusOpenFoodFacts = 0;
    final detalhesOpenFoodFacts = <String>[];

    // 2.1. Manufacturing Places (15 pontos)
    // Analisa local de fabricação do produto
    if (manufacturingPlaces != null && manufacturingPlaces.isNotEmpty) {
      if (_contemBrasil(manufacturingPlaces)) {
        bonusOpenFoodFacts += 15;
        detalhesOpenFoodFacts.add('Fabricado no Brasil: $manufacturingPlaces');
        print('✓ Manufacturing Places indica Brasil: $manufacturingPlaces');
      } else {
        detalhesOpenFoodFacts.add('Local de fabricação: $manufacturingPlaces');
      }
    }

    // 2.2. Origins (10 pontos)
    // Analisa origem dos ingredientes
    if (origins != null && origins.isNotEmpty) {
      if (_contemBrasil(origins)) {
        bonusOpenFoodFacts += 10;
        detalhesOpenFoodFacts.add('Ingredientes do Brasil: $origins');
        print('✓ Origins indica Brasil: $origins');
      } else {
        detalhesOpenFoodFacts.add('Origem dos ingredientes: $origins');
      }
    }

    // 2.3. Countries Tags (20 pontos)
    // Analisa tags de países associadas ao produto
    if (countriesTags.isNotEmpty) {
      final temBrasilTag = countriesTags.any(
        (tag) =>
            tag.toLowerCase().contains('brazil') ||
            tag.toLowerCase().contains('brasil') ||
            tag.toLowerCase().contains('br'),
      );

      if (temBrasilTag) {
        bonusOpenFoodFacts += 20;
        detalhesOpenFoodFacts.add('Tags de país incluem Brasil: ${countriesTags.join(', ')}');
        print('✓ Countries Tags indica Brasil: ${countriesTags.join(', ')}');
      } else {
        detalhesOpenFoodFacts.add('Tags de países: ${countriesTags.join(', ')}');
      }
    }

    // 2.4. Made In (25 pontos)
    // Analisa indicação específica de fabricação
    if (madeIn != null && madeIn.isNotEmpty) {
      if (_contemBrasil(madeIn)) {
        bonusOpenFoodFacts += 25;
        detalhesOpenFoodFacts.add('Fabricado em: $madeIn');
        print('✓ Made In indica Brasil: $madeIn');
      } else {
        detalhesOpenFoodFacts.add('Fabricado em: $madeIn');
      }
    }

    // ETAPA 3: Criação da análise atualizada
    final novaAnalise = AnaliseResult(
      marca: analiseExistente.marca,
      origem: analiseExistente.origem,
      fabricacao: analiseExistente.fabricacao,
      propriedadeLocal: analiseExistente.propriedadeLocal,
      propriedadeMatriz: analiseExistente.propriedadeMatriz,
      cadeiaProprietaria: analiseExistente.cadeiaProprietaria,
      grauBrasileiridade: analiseExistente.grauBrasileiridade,
      classificacao: analiseExistente.classificacao,
      detalhes: [...analiseExistente.detalhes, ...detalhesOpenFoodFacts],
      semDados: analiseExistente.semDados,
      // Dados específicos do OpenFoodFacts
      manufacturingPlaces: manufacturingPlaces,
      origins: origins,
      countriesTags: countriesTags,
      madeIn: madeIn,
      bonusOpenFoodFacts: bonusOpenFoodFacts,
    );

    // ETAPA 4: Recálculo do grau de brasileiridade com bônus
    if (!novaAnalise.semDados && novaAnalise.grauBrasileiridade != null) {
      print('📊 Recalculando grau de brasileiridade:');
      print('   - Grau base: ${novaAnalise.grauBrasileiridade}%');
      print('   - Bônus OpenFoodFacts: +${bonusOpenFoodFacts} pontos');

      // Aplicação do bônus limitado a 100%
      final novoGrau = (novaAnalise.grauBrasileiridade! + bonusOpenFoodFacts).clamp(0, 100);
      novaAnalise.grauBrasileiridade = novoGrau;
      novaAnalise.classificacao = _classificarBrasileiridade(novoGrau);

      print('   - Novo grau: ${novoGrau}%');
      print('   - Nova classificação: ${novaAnalise.classificacao}');

      // Log do bônus aplicado
      if (bonusOpenFoodFacts > 0) {
        novaAnalise.detalhes.add('Bônus OpenFoodFacts: +$bonusOpenFoodFacts pontos');
        print('✓ Bônus OpenFoodFacts aplicado: +$bonusOpenFoodFacts pontos');
        print('✓ Novo grau de brasileiridade: $novoGrau%');
      }
    }

    return novaAnalise;
  }

  // ==========================================================================
  // FUNÇÕES DE DETECÇÃO GEOGRÁFICA
  // ==========================================================================

  /// Detecta referências ao Brasil em textos
  ///
  /// TERMOS DETECTADOS:
  /// • Variações do nome: brasil, brazil, br
  /// • Principais cidades: São Paulo, Rio de Janeiro, Brasília, etc.
  /// • Capitais estaduais: Belo Horizonte, Salvador, Fortaleza, etc.
  ///
  /// @param texto Texto a ser analisado
  /// @return true se contém referências ao Brasil
  static bool _contemBrasil(String texto) {
    final textoLower = texto.toLowerCase();
    return textoLower.contains('brasil') ||
        textoLower.contains('brazil') ||
        textoLower.contains('br') ||
        textoLower.contains('são paulo') ||
        textoLower.contains('rio de janeiro') ||
        textoLower.contains('minas gerais') ||
        textoLower.contains('brasília') ||
        textoLower.contains('belo horizonte') ||
        textoLower.contains('salvador') ||
        textoLower.contains('fortaleza') ||
        textoLower.contains('recife') ||
        textoLower.contains('porto alegre') ||
        textoLower.contains('curitiba') ||
        textoLower.contains('goiânia') ||
        textoLower.contains('manaus') ||
        textoLower.contains('belém');
  }

  /// Detecta envolvimento americano na análise completa
  ///
  /// CAMPOS ANALISADOS:
  /// • Dados do Wikidata: origem, fabricação, cadeia proprietária
  /// • Dados do OpenFoodFacts: manufacturing_places, origins, made_in, countries_tags
  ///
  /// @param analise Resultado da análise de brasileiridade
  /// @return true se há envolvimento americano detectado
  static bool temEnvolvimentoAmericano(AnaliseResult analise) {
    // Lista de todos os textos a serem analisados
    final textos = [
      analise.origem,
      analise.fabricacao,
      analise.propriedadeLocal,
      analise.propriedadeMatriz,
      ...analise.cadeiaProprietaria,
      analise.manufacturingPlaces,
      analise.origins,
      analise.madeIn,
      ...(analise.countriesTags ?? []),
    ];

    // Verifica cada texto em busca de referências americanas
    for (final texto in textos) {
      if (texto != null && _contemEUA(texto)) {
        return true;
      }
    }

    return false;
  }

  /// Verifica se o produto é considerado brasileiro
  ///
  /// CRITÉRIO: Grau de brasileiridade ≥ 65%
  /// Corresponde às classificações "Majoritariamente" e "Totalmente" brasileira
  ///
  /// @param analise Resultado da análise de brasileiridade
  /// @return true se o produto é considerado brasileiro
  static bool eProdutoBrasileiro(AnaliseResult analise) {
    return !analise.semDados &&
        analise.grauBrasileiridade != null &&
        analise.grauBrasileiridade! >= 65;
  }

  /// Detecta referências aos Estados Unidos em textos
  ///
  /// TERMOS DETECTADOS:
  /// • Variações do nome: Estados Unidos, United States, USA, US, America, American
  /// • Principais cidades: New York, Los Angeles, Chicago, Miami, etc.
  /// • Estados: California, Texas, Florida, Washington, etc.
  ///
  /// @param texto Texto a ser analisado
  /// @return true se contém referências aos EUA
  static bool _contemEUA(String texto) {
    final textoLower = texto.toLowerCase();
    return textoLower.contains('estados unidos') ||
        textoLower.contains('united states') ||
        textoLower.contains('usa') ||
        textoLower.contains('us') ||
        textoLower.contains('america') ||
        textoLower.contains('american') ||
        textoLower.contains('new york') ||
        textoLower.contains('california') ||
        textoLower.contains('texas') ||
        textoLower.contains('florida') ||
        textoLower.contains('chicago') ||
        textoLower.contains('atlanta') ||
        textoLower.contains('boston') ||
        textoLower.contains('detroit') ||
        textoLower.contains('seattle') ||
        textoLower.contains('denver') ||
        textoLower.contains('washington') ||
        textoLower.contains('philadelphia') ||
        textoLower.contains('phoenix') ||
        textoLower.contains('las vegas') ||
        textoLower.contains('miami') ||
        textoLower.contains('dallas') ||
        textoLower.contains('houston') ||
        textoLower.contains('los angeles');
  }

  // ==========================================================================
  // FUNÇÕES AUXILIARES E UTILITÁRIAS
  // ==========================================================================

  /// Realiza requisições HTTP com sistema de retry
  ///
  /// CARACTERÍSTICAS:
  /// • Retry automático em caso de erro de servidor (5xx)
  /// • Timeout de 8 segundos por tentativa
  /// • User-Agent personalizado para identificação
  /// • Tratamento de erros com logs detalhados
  ///
  /// @param url URL para requisição
  /// @param maxRetries Número máximo de tentativas (padrão: 2)
  /// @return Response HTTP ou null em caso de erro
  static Future<http.Response?> _fetchComRetry(String url, {int maxRetries = 2}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final response = await http
            .get(Uri.parse(url), headers: {'User-Agent': _userAgent})
            .timeout(Duration(milliseconds: _timeout));

        if (response.statusCode == 200) {
          return response;
        } else if (response.statusCode >= 500 && i < maxRetries - 1) {
          // Servidor ocupado, tenta novamente
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

  /// Normaliza nome da marca para busca
  ///
  /// PROCESSAMENTO:
  /// • Remove espaços extras
  /// • Normaliza aspas e caracteres especiais
  /// • Converte hífens especiais para hífen padrão
  ///
  /// @param marca Nome da marca a ser normalizado
  /// @return Nome normalizado
  static String _normalizarMarca(String marca) {
    return marca
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // Remove espaços extras
        .replaceAll(
          RegExp(
            r'[""'
            ']',
          ),
          '"',
        ) // Normaliza aspas
        .replaceAll(RegExp(r'[–—]'), '-'); // Normaliza hífens
  }

  /// Gera múltiplas variações de uma marca para otimizar buscas
  ///
  /// ESTRATÉGIA:
  /// • Aumenta chances de encontrar dados no Wikidata
  /// • Trata diferentes padrões de escrita e capitalização
  /// • Gera variações específicas para marcas com espaços
  ///
  /// VARIAÇÕES GERADAS:
  /// • Capitalização: original, minúscula, maiúscula, primeira letra, title case
  /// • Espaços: com espaços, sem espaços, com hífens, com underscores
  /// • Palavras: primeira palavra, última palavra
  ///
  /// @param marca Nome da marca normalizado
  /// @return Lista de variações para busca
  static List<String> _gerarVariacoesMarca(String marca) {
    final variacoes = <String>{};

    // Variação original
    variacoes.add(marca);

    // Variações básicas de capitalização
    variacoes.add(marca.toLowerCase());
    variacoes.add(marca.toUpperCase());
    variacoes.add(_capitalize(marca));
    variacoes.add(_titleCase(marca));

    // Tratamento especial para marcas com espaços
    if (marca.contains(' ')) {
      final marcaLimpa = marca.trim();

      // Variação sem espaços (Ex: "Coca Cola" → "CocaCola")
      final semEspacos = marcaLimpa.replaceAll(' ', '');
      variacoes.add(semEspacos);
      variacoes.add(semEspacos.toLowerCase());
      variacoes.add(semEspacos.toUpperCase());
      variacoes.add(_capitalize(semEspacos));

      // Variação com hífens (Ex: "Coca Cola" → "Coca-Cola")
      final comHifens = marcaLimpa.replaceAll(' ', '-');
      variacoes.add(comHifens);
      variacoes.add(comHifens.toLowerCase());
      variacoes.add(comHifens.toUpperCase());
      variacoes.add(_capitalize(comHifens));
      variacoes.add(_titleCase(comHifens));

      // Variação com espaços normalizados (Ex: "Coca  Cola" → "Coca Cola")
      final espacosNormalizados = marcaLimpa.replaceAll(RegExp(r'\s+'), ' ');
      variacoes.add(espacosNormalizados);
      variacoes.add(espacosNormalizados.toLowerCase());
      variacoes.add(espacosNormalizados.toUpperCase());
      variacoes.add(_capitalize(espacosNormalizados));
      variacoes.add(_titleCase(espacosNormalizados));

      // Variação com underscores (Ex: "Coca Cola" → "Coca_Cola")
      final comUnderscores = marcaLimpa.replaceAll(' ', '_');
      variacoes.add(comUnderscores);
      variacoes.add(comUnderscores.toLowerCase());
      variacoes.add(comUnderscores.toUpperCase());

      // Variações de palavras individuais para marcas compostas
      final palavras = marcaLimpa.split(' ').where((p) => p.isNotEmpty).toList();
      if (palavras.length > 1) {
        // Primeira palavra apenas
        variacoes.add(palavras.first);
        variacoes.add(palavras.first.toLowerCase());
        variacoes.add(palavras.first.toUpperCase());
        variacoes.add(_capitalize(palavras.first));

        // Última palavra apenas
        variacoes.add(palavras.last);
        variacoes.add(palavras.last.toLowerCase());
        variacoes.add(palavras.last.toUpperCase());
        variacoes.add(_capitalize(palavras.last));
      }
    }

    print('Variações geradas para "$marca": ${variacoes.join(', ')}');
    return variacoes.toList();
  }

  /// Capitaliza apenas a primeira letra
  /// @param text Texto a ser capitalizado
  /// @return Texto com primeira letra maiúscula
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Aplica title case (primeira letra de cada palavra maiúscula)
  /// @param text Texto a ser convertido
  /// @return Texto em title case
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

  // ==========================================================================
  // ALGORITMO DE CÁLCULO DE BRASILEIRIDADE
  // ==========================================================================

  /// Calcula o grau de brasileiridade baseado em análise ponderada
  ///
  /// METODOLOGIA:
  /// 1. Sistema de pontuação ponderada com pesos específicos
  /// 2. Análise hierárquica da cadeia proprietária (matriz > local)
  /// 3. Consideração de fabricação e origem histórica
  /// 4. Bônus para cadeias completamente brasileiras
  /// 5. Normalização para escala 0-100%
  ///
  /// CRITÉRIOS E PESOS:
  /// • Propriedade Matriz: 40% (controle final da empresa)
  /// • Propriedade Local: 30% (controle direto da marca)
  /// • Fabricação/Sede: 20% (localização operacional)
  /// • Origem: 10% (país de origem histórica)
  /// • Bônus Cadeia: 5% (toda cadeia no Brasil)
  static int _calcularGrauBrasileiridade(AnaliseResult analise) {
    int pontos = 0; // Pontos acumulados
    int maxPontos = 0; // Máximo de pontos possíveis

    // Definição dos pesos por critério (importância relativa)
    const pesos = {
      'propriedadeMatriz': 40, // Controle final (mais importante)
      'propriedadeLocal': 30, // Controle direto
      'fabricacao': 20, // Operação/sede
      'origem': 10, // Origem histórica (menos importante)
    };

    // CRITÉRIO 1: Propriedade Matriz (40 pontos)
    // Avalia se a empresa controladora final está no Brasil
    maxPontos += pesos['propriedadeMatriz']!;
    if (analise.propriedadeMatriz != null && analise.propriedadeMatriz!.contains('Brasil')) {
      pontos += pesos['propriedadeMatriz']!;
    }

    // CRITÉRIO 2: Propriedade Local (30 pontos)
    // Avalia se a empresa proprietária direta está no Brasil
    maxPontos += pesos['propriedadeLocal']!;
    if (analise.propriedadeLocal != null && analise.propriedadeLocal!.contains('Brasil')) {
      pontos += pesos['propriedadeLocal']!;
    }

    // CRITÉRIO 3: Fabricação/Sede (20 pontos)
    // Avalia se a produção ou sede principal está no Brasil
    maxPontos += pesos['fabricacao']!;
    if (analise.fabricacao == 'Brasil') {
      pontos += pesos['fabricacao']!;
    }

    // CRITÉRIO 4: Origem da Marca (10 pontos)
    // Avalia se a marca foi criada/fundada no Brasil
    maxPontos += pesos['origem']!;
    if (analise.origem == 'Brasil') {
      pontos += pesos['origem']!;
    }

    // BÔNUS: Cadeia Proprietária Completamente Brasileira (5 pontos)
    // Incentiva empresas com toda cadeia de controle no Brasil
    if (analise.cadeiaProprietaria.isNotEmpty) {
      final todasBrasileiras = analise.cadeiaProprietaria.every(
        (empresa) => empresa.contains('Brasil'),
      );
      if (todasBrasileiras) {
        pontos += 5;
        maxPontos += 5;
      }
    }

    // NORMALIZAÇÃO: Converte para escala 0-100%
    // Fórmula: (pontos obtidos / pontos máximos) * 100
    return ((pontos / maxPontos) * 100).round();
  }

  /// Classifica o grau de brasileiridade em categorias descritivas
  ///
  /// ESCALA DE CLASSIFICAÇÃO:
  /// • 85-100%: Totalmente Brasileira (controle e operação no Brasil)
  /// • 65-84%: Majoritariamente Brasileira (controle principal no Brasil)
  /// • 45-64%: Parcialmente Brasileira (presença significativa no Brasil)
  /// • 25-44%: Pouco Brasileira (baixa conexão com o Brasil)
  /// • 1-24%: Minimamente Brasileira (conexão mínima com o Brasil)
  /// • 0%: Marca Estrangeira (sem conexão identificada com o Brasil)
  static String _classificarBrasileiridade(int grau) {
    if (grau >= 85) return '🇧🇷 Totalmente Brasileira'; // 85-100%
    if (grau >= 65) return '🟢 Majoritariamente Brasileira'; // 65-84%
    if (grau >= 45) return '🟡 Parcialmente Brasileira'; // 45-64%
    if (grau >= 25) return '🟠 Pouco Brasileira'; // 25-44%
    if (grau > 0) return '🔴 Minimamente Brasileira'; // 1-24%
    return '🌍 Marca Estrangeira'; // 0%
  }

  /// Gera lista de detalhes descritivos da análise
  ///
  /// INFORMAÇÕES INCLUÍDAS:
  /// • Origem da marca (se disponível)
  /// • Fabricação/Sede (se disponível)
  /// • Cadeia proprietária completa (se disponível)
  ///
  /// @param analise Resultado da análise
  /// @return Lista de strings com detalhes
  static List<String> _gerarDetalhesAnalise(AnaliseResult analise) {
    final detalhes = <String>[];

    // Adiciona origem se disponível
    if (analise.origem != null) {
      detalhes.add('Origem: ${analise.origem}');
    }

    // Adiciona fabricação/sede se disponível
    if (analise.fabricacao != null) {
      detalhes.add('Fabricação/Sede: ${analise.fabricacao}');
    }

    // Adiciona cadeia proprietária se disponível
    if (analise.cadeiaProprietaria.isNotEmpty) {
      detalhes.add('Cadeia proprietária: ${analise.cadeiaProprietaria.join(' → ')}');
    }

    return detalhes;
  }

  /// Retorna análise fictícia para produtos de teste
  static AnaliseResult _getFakeAnalysisResult(String marca) {
    print('🔍 Buscando dados fictícios para: "$marca"');

    final fakeAnalysis = {
      'Marca Brasileira LTDA': AnaliseResult(
        marca: 'Marca Brasileira LTDA',
        origem: 'Brasil',
        fabricacao: 'Brasil',
        propriedadeLocal: 'Empresa Brasileira S.A. (Brasil)',
        propriedadeMatriz: 'Holding Brasileira LTDA (Brasil)',
        cadeiaProprietaria: [
          'Empresa Brasileira S.A. (Brasil)',
          'Holding Brasileira LTDA (Brasil)',
        ],
        grauBrasileiridade: 90, // Base 90% (já "Totalmente Brasileira")
        classificacao: '🇧🇷 Totalmente Brasileira',
        detalhes: [
          'Origem: Brasil',
          'Fabricação/Sede: Brasil',
          'Cadeia proprietária: Empresa Brasileira S.A. (Brasil) → Holding Brasileira LTDA (Brasil)',
        ],
        manufacturingPlaces: 'São Paulo, Brasil',
        origins: 'Ingredientes do Brasil',
        countriesTags: ['en:brazil', 'pt:brasil'],
        madeIn: 'Brasil',
        bonusOpenFoodFacts: 0, // Will be calculated by OpenFoodFacts integration
      ),
      'Empresa Majoritariamente Brasileira': AnaliseResult(
        marca: 'Empresa Majoritariamente Brasileira',
        origem: 'Brasil',
        fabricacao: 'Brasil',
        propriedadeLocal: 'Empresa Brasileira S.A. (Brasil)',
        propriedadeMatriz: 'Multinacional Latino-Argentina (Argentina)',
        cadeiaProprietaria: [
          'Empresa Brasileira S.A. (Brasil)',
          'Multinacional Latino-Argentina (Argentina)',
        ],
        grauBrasileiridade: 5, // Base 5% + 70% bonus = 75%
        classificacao: '🟢 Majoritariamente Brasileira',
        detalhes: [
          'Origem: Brasil',
          'Fabricação/Sede: Brasil',
          'Cadeia proprietária: Empresa Brasileira S.A. (Brasil) → Multinacional Latino-Argentina (Argentina)',
        ],
        manufacturingPlaces: 'Rio de Janeiro, Brasil',
        origins: 'Ingredientes Brasileiros e Importados',
        countriesTags: ['en:brazil', 'en:argentina'],
        madeIn: 'Brasil',
        bonusOpenFoodFacts: 0, // Will be calculated by OpenFoodFacts integration
      ),
      'Empresa Parcialmente Brasileira': AnaliseResult(
        marca: 'Empresa Parcialmente Brasileira',
        origem: 'Argentina',
        fabricacao: 'Brasil',
        propriedadeLocal: 'Empresa Regional S.A. (Argentina)',
        propriedadeMatriz: 'Holding Internacional (Espanha)',
        cadeiaProprietaria: [
          'Empresa Regional S.A. (Argentina)',
          'Holding Internacional (Espanha)',
        ],
        grauBrasileiridade: 5, // Base 5% + 45% bonus = 50%
        classificacao: '🟡 Parcialmente Brasileira',
        detalhes: [
          'Origem: Argentina',
          'Fabricação/Sede: Brasil',
          'Cadeia proprietária: Empresa Regional S.A. (Argentina) → Holding Internacional (Espanha)',
        ],
        manufacturingPlaces: 'Argentina',
        origins: 'Ingredientes Mistos',
        countriesTags: ['en:brazil', 'en:argentina'],
        madeIn: 'Brasil',
        bonusOpenFoodFacts: 0, // Will be calculated by OpenFoodFacts integration
      ),
      'Empresa Pouco Brasileira': AnaliseResult(
        marca: 'Empresa Pouco Brasileira',
        origem: 'México',
        fabricacao: 'México',
        propriedadeLocal: 'Empresa Mexicana S.A. (México)',
        propriedadeMatriz: 'Corporação Internacional (Canadá)',
        cadeiaProprietaria: ['Empresa Mexicana S.A. (México)', 'Corporação Internacional (Canadá)'],
        grauBrasileiridade: 10, // Base 10% + 20% bonus = 30%
        classificacao: '🟠 Pouco Brasileira',
        detalhes: [
          'Origem: México',
          'Fabricação/Sede: México',
          'Cadeia proprietária: Empresa Mexicana S.A. (México) → Corporação Internacional (Canadá)',
        ],
        manufacturingPlaces: 'México',
        origins: 'Ingredientes Importados',
        countriesTags: ['en:mexico', 'en:brazil'],
        madeIn: 'México',
        bonusOpenFoodFacts: 0, // Will be calculated by OpenFoodFacts integration
      ),
      'Empresa Minimamente Brasileira': AnaliseResult(
        marca: 'Empresa Minimamente Brasileira',
        origem: 'Chile',
        fabricacao: 'Chile',
        propriedadeLocal: 'Empresa Chilena LTDA (Chile)',
        propriedadeMatriz: 'Multinacional Européia (França)',
        cadeiaProprietaria: ['Empresa Chilena LTDA (Chile)', 'Multinacional Européia (França)'],
        grauBrasileiridade: 15, // Base 15% + 0% bonus = 15%
        classificacao: '🔴 Minimamente Brasileira',
        detalhes: [
          'Origem: Chile',
          'Fabricação/Sede: Chile',
          'Cadeia proprietária: Empresa Chilena LTDA (Chile) → Multinacional Européia (França)',
        ],
        manufacturingPlaces: 'Chile',
        origins: 'Ingredientes Chilenos',
        countriesTags: ['en:chile'],
        madeIn: 'Chile',
        bonusOpenFoodFacts: 0, // Will be calculated by OpenFoodFacts integration
      ),
      'Marca Estrangeira Internacional': AnaliseResult(
        marca: 'Marca Estrangeira Internacional',
        origem: 'França',
        fabricacao: 'França',
        propriedadeLocal: 'Société Française S.A. (França)',
        propriedadeMatriz: 'Groupe International (França)',
        cadeiaProprietaria: ['Société Française S.A. (França)', 'Groupe International (França)'],
        grauBrasileiridade: 0,
        classificacao: '🌍 Marca Estrangeira',
        detalhes: [
          'Origem: França',
          'Fabricação/Sede: França',
          'Cadeia proprietária: Société Française S.A. (França) → Groupe International (França)',
          'Local de fabricação: França',
          'Origem dos ingredientes: Ingredientes Franceses',
          'Tags de países: en:france',
          'Fabricado em: França',
        ],
        manufacturingPlaces: 'França',
        origins: 'Ingredientes Franceses',
        countriesTags: ['en:france'],
        madeIn: 'França',
        bonusOpenFoodFacts: 0,
      ),
      'American Corporation': AnaliseResult(
        marca: 'American Corporation',
        origem: 'Estados Unidos',
        fabricacao: 'Estados Unidos',
        propriedadeLocal: 'American Holdings Inc. (Estados Unidos)',
        propriedadeMatriz: 'US Global Corporation (Estados Unidos)',
        cadeiaProprietaria: [
          'American Holdings Inc. (Estados Unidos)',
          'US Global Corporation (Estados Unidos)',
        ],
        grauBrasileiridade: 0, // Base 0% + 0% bonus = 0%
        classificacao: '🌍 Marca Estrangeira',
        detalhes: [
          'Origem: Estados Unidos',
          'Fabricação/Sede: Estados Unidos',
          'Cadeia proprietária: American Holdings Inc. (Estados Unidos) → US Global Corporation (Estados Unidos)',
        ],
        manufacturingPlaces: 'California, Estados Unidos',
        origins: 'Ingredientes Americanos',
        countriesTags: ['en:united-states'],
        madeIn: 'Estados Unidos',
        bonusOpenFoodFacts: 0, // Will be calculated by OpenFoodFacts integration
      ),
    };

    // Procura pela marca correspondente nos dados fictícios
    for (final entry in fakeAnalysis.entries) {
      if (marca.contains(entry.key)) {
        print('✓ Dados fictícios encontrados para: "${entry.key}"');
        print('✓ Grau de brasileiridade: ${entry.value.grauBrasileiridade}%');
        print('✓ Classificação: ${entry.value.classificacao}');
        return entry.value;
      }
    }

    // Busca específica para códigos FAKE (prioridade alta)
    if (marca.contains('FAKE100')) {
      print('✓ FAKE100 detectado - retornando dados da "Marca Brasileira LTDA"');
      final resultado = fakeAnalysis['Marca Brasileira LTDA']!;
      print('✓ Grau final: ${resultado.grauBrasileiridade}%');
      return resultado;
    }
    if (marca.contains('FAKE75')) {
      print('✓ FAKE75 detectado - retornando dados da "Empresa Majoritariamente Brasileira"');
      final resultado = fakeAnalysis['Empresa Majoritariamente Brasileira']!;
      print('✓ Grau final: ${resultado.grauBrasileiridade}%');
      return resultado;
    }
    if (marca.contains('FAKE50')) {
      print('✓ FAKE50 detectado - retornando dados da "Empresa Parcialmente Brasileira"');
      final resultado = fakeAnalysis['Empresa Parcialmente Brasileira']!;
      print('✓ Grau final: ${resultado.grauBrasileiridade}%');
      return resultado;
    }
    if (marca.contains('FAKE30')) {
      print('✓ FAKE30 detectado - retornando dados da "Empresa Pouco Brasileira"');
      final resultado = fakeAnalysis['Empresa Pouco Brasileira']!;
      print('✓ Grau final: ${resultado.grauBrasileiridade}%');
      return resultado;
    }
    if (marca.contains('FAKE15')) {
      print('✓ FAKE15 detectado - retornando dados da "Empresa Minimamente Brasileira"');
      final resultado = fakeAnalysis['Empresa Minimamente Brasileira']!;
      print('✓ Grau final: ${resultado.grauBrasileiridade}%');
      return resultado;
    }
    if (marca.contains('FAKE0')) {
      print('✓ FAKE0 detectado - retornando dados da "Marca Estrangeira Internacional"');
      final resultado = fakeAnalysis['Marca Estrangeira Internacional']!;
      print('✓ Grau final: ${resultado.grauBrasileiridade}%');
      return resultado;
    }
    if (marca.contains('FAKEUSA')) {
      print('✓ FAKEUSA detectado - retornando dados da "American Corporation"');
      final resultado = fakeAnalysis['American Corporation']!;
      print('✓ Grau final: ${resultado.grauBrasileiridade}%');
      return resultado;
    }

    print('⚠️ Produto FAKE não encontrado nos dados fictícios: "$marca"');

    // Fallback para marca não encontrada
    return AnaliseResult(
      marca: marca,
      origem: null,
      fabricacao: null,
      propriedadeLocal: null,
      propriedadeMatriz: null,
      cadeiaProprietaria: [],
      grauBrasileiridade: null,
      classificacao: '❓ Análise não foi possível',
      detalhes: ['Dados fictícios não encontrados'],
      semDados: true,
    );
  }
}

// =============================================================================
// CLASSE DE RESULTADO DA ANÁLISE
// =============================================================================

/// Representa o resultado completo da análise de brasileiridade
///
/// DADOS PRINCIPAIS:
/// • marca: Nome da marca analisada
/// • grauBrasileiridade: Porcentagem de brasileiridade (0-100)
/// • classificacao: Categoria descritiva da brasileiridade
/// • detalhes: Lista de informações detalhadas
///
/// DADOS DO WIKIDATA:
/// • origem: País de origem da marca
/// • fabricacao: País de fabricação/sede
/// • propriedadeLocal: Empresa proprietária direta
/// • propriedadeMatriz: Empresa controladora final
/// • cadeiaProprietaria: Lista completa da cadeia de propriedade
///
/// DADOS DO OPENFOODFACTS:
/// • manufacturingPlaces: Locais de fabricação
/// • origins: Origem dos ingredientes
/// • countriesTags: Tags de países
/// • madeIn: Indicação de fabricação
/// • bonusOpenFoodFacts: Pontos extras obtidos
///
/// CONTROLE:
/// • semDados: Indica se análise foi possível
class AnaliseResult {
  // Dados principais
  final String marca;
  int? grauBrasileiridade;
  String classificacao;
  List<String> detalhes;
  bool semDados;

  // Dados do Wikidata
  String? origem;
  String? fabricacao;
  String? propriedadeLocal;
  String? propriedadeMatriz;
  List<String> cadeiaProprietaria;

  // Dados do OpenFoodFacts
  String? manufacturingPlaces;
  String? origins;
  List<String>? countriesTags;
  String? madeIn;
  int? bonusOpenFoodFacts;

  /// Construtor da classe AnaliseResult
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
    this.manufacturingPlaces,
    this.origins,
    this.countriesTags,
    this.madeIn,
    this.bonusOpenFoodFacts,
  });

  /// Converte o resultado da análise para formato JSON
  ///
  /// UTILIDADE:
  /// • Serialização para armazenamento
  /// • Transmissão de dados via API
  /// • Persistência em banco de dados
  ///
  /// @return Map com String e dynamic contendo todos os dados
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
      'manufacturingPlaces': manufacturingPlaces,
      'origins': origins,
      'countriesTags': countriesTags,
      'madeIn': madeIn,
      'bonusOpenFoodFacts': bonusOpenFoodFacts,
    };
  }

  /// Cria instância de AnaliseResult a partir de dados JSON
  ///
  /// UTILIDADE:
  /// • Deserialização de dados armazenados
  /// • Reconstrução de objetos a partir de API
  /// • Recuperação de dados do banco
  ///
  /// @param json Map com String e dynamic contendo dados serializados
  /// @return Nova instância de AnaliseResult
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
      manufacturingPlaces: json['manufacturingPlaces'],
      origins: json['origins'],
      countriesTags: json['countriesTags']?.cast<String>(),
      madeIn: json['madeIn'],
      bonusOpenFoodFacts: json['bonusOpenFoodFacts'],
    );
  }
}
