import 'brasileiridade_algorithm.dart';

/// DADOS DE TESTE PARA DESENVOLVIMENTO
///
/// Este arquivo contém dados fictícios para teste do algoritmo de brasileiridade.
/// São produtos FAKE com resultados pré-definidos para validação e demonstração.
///
/// PRODUTOS DISPONÍVEIS:
/// • FAKE100: Marca Brasileira LTDA (90% + bônus = 100%)
/// • FAKE75: Empresa Majoritariamente Brasileira (5% + 70% bônus = 75%)
/// • FAKE50: Empresa Parcialmente Brasileira (5% + 45% bônus = 50%)
/// • FAKE30: Empresa Pouco Brasileira (10% + 20% bônus = 30%)
/// • FAKE15: Empresa Minimamente Brasileira (15% + 0% bônus = 15%)
/// • FAKE0: Marca Estrangeira Internacional (0% + 0% bônus = 0%)
/// • FAKEUSA: American Corporation (0% + 0% bônus = 0%)
class BrasileiridadeTestData {
  /// Verifica se uma marca é um produto de teste FAKE
  ///
  /// @param marca Nome da marca a verificar
  /// @return true se é um produto FAKE de teste
  static bool isFakeProduct(String marca) {
    return marca.contains('FAKE') ||
        marca.contains('Marca Brasileira LTDA') ||
        marca.contains('Empresa Majoritariamente Brasileira') ||
        marca.contains('Empresa Parcialmente Brasileira') ||
        marca.contains('Empresa Pouco Brasileira') ||
        marca.contains('Empresa Minimamente Brasileira') ||
        marca.contains('Marca Estrangeira Internacional') ||
        marca.contains('American Corporation');
  }

  /// Retorna análise fictícia para produtos de teste
  ///
  /// @param marca Nome da marca FAKE
  /// @return AnaliseResult com dados fictícios
  static AnaliseResult getFakeAnalysisResult(String marca) {
    print('[FAKE] Produto FAKE detectado - usando dados isolados: "$marca"');

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
        classificacao: 'BR Totalmente Brasileira',
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
        classificacao: 'STAR Majoritariamente Brasileira',
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
        classificacao: 'STAR Parcialmente Brasileira',
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
        classificacao: 'STAR Pouco Brasileira',
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
        classificacao: 'WARNING Minimamente Brasileira',
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
        classificacao: 'WORLD Marca Estrangeira',
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
        classificacao: 'WORLD Marca Estrangeira',
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

    print('[AVISO] Produto FAKE não encontrado nos dados fictícios: "$marca"');

    // Fallback para marca não encontrada
    return AnaliseResult(
      marca: marca,
      origem: null,
      fabricacao: null,
      propriedadeLocal: null,
      propriedadeMatriz: null,
      cadeiaProprietaria: [],
      grauBrasileiridade: null,
      classificacao: 'QUESTION Análise não foi possível',
      detalhes: ['Dados fictícios não encontrados'],
      semDados: true,
    );
  }
}
