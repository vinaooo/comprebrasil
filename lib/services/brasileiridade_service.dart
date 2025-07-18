import 'brasileiridade_algorithm.dart';
import 'brasileiridade_test_data.dart';

// Exporta as classes principais para uso externo
export 'brasileiridade_algorithm.dart' show AnaliseResult;

/// SERVIÇO PRINCIPAL DE BRASILEIRIDADE
///
/// Esta classe serve como ponto de entrada único para o algoritmo de brasileiridade,
/// integrando o algoritmo principal com os dados de teste quando necessário.
///
/// FUNCIONALIDADES:
/// • Detecção automática de produtos FAKE vs produtos reais
/// • Roteamento para algoritmo principal ou dados de teste
/// • Interface unificada para o resto da aplicação
/// • Funções de utilidade para análise de resultados
class BrasileiridadeService {
  // ==========================================================================
  // FUNÇÕES PRINCIPAIS
  // ==========================================================================

  /// Analisa a brasileiridade de uma marca individual
  ///
  /// ROTEAMENTO AUTOMÁTICO:
  /// • Se for produto FAKE → usa dados de teste
  /// • Se for produto real → usa algoritmo principal
  ///
  /// @param marca Nome da marca a ser analisada
  /// @return AnaliseResult com grau de brasileiridade e detalhes
  static Future<AnaliseResult> analisarBrasileiridade(String marca) async {
    // Verifica se é um produto FAKE para teste
    if (BrasileiridadeTestData.isFakeProduct(marca)) {
      return BrasileiridadeTestData.getFakeAnalysisResult(marca);
    }

    // Usa o algoritmo principal para produtos reais
    return await BrasileiridadeAlgorithm.analisarBrasileiridade(marca);
  }

  /// Analisa múltiplas marcas e retorna a com maior grau de brasileiridade
  ///
  /// @param marcasString String com marcas separadas por vírgula
  /// @return AnaliseResult da marca mais brasileira
  static Future<AnaliseResult> analisarMultiplasMarcas(String marcasString) async {
    // Delega para o algoritmo principal (que já faz o roteamento interno)
    return await BrasileiridadeAlgorithm.analisarMultiplasMarcas(marcasString);
  }

  /// Complementa análise Wikidata com dados do OpenFoodFacts
  ///
  /// @param productData Dados do produto do OpenFoodFacts
  /// @param analiseExistente Análise prévia do Wikidata
  /// @return AnaliseResult atualizada com dados do OpenFoodFacts
  static AnaliseResult analisarDadosOpenFoodFacts(
    Map<String, dynamic> productData,
    AnaliseResult analiseExistente,
  ) {
    return BrasileiridadeAlgorithm.analisarDadosOpenFoodFacts(productData, analiseExistente);
  }

  // ==========================================================================
  // FUNÇÕES DE UTILIDADE
  // ==========================================================================

  /// Detecta envolvimento americano na análise completa
  ///
  /// @param analise Resultado da análise de brasileiridade
  /// @return true se há envolvimento americano detectado
  static bool temEnvolvimentoAmericano(AnaliseResult analise) {
    return BrasileiridadeAlgorithm.temEnvolvimentoAmericano(analise);
  }

  /// Verifica se o produto é considerado brasileiro
  ///
  /// CRITÉRIO: Grau de brasileiridade ≥ 65%
  ///
  /// @param analise Resultado da análise de brasileiridade
  /// @return true se o produto é considerado brasileiro
  static bool eProdutoBrasileiro(AnaliseResult analise) {
    return BrasileiridadeAlgorithm.eProdutoBrasileiro(analise);
  }

  /// Verifica se uma marca é um produto de teste FAKE
  ///
  /// @param marca Nome da marca a verificar
  /// @return true se é um produto FAKE de teste
  static bool isFakeProduct(String marca) {
    return BrasileiridadeTestData.isFakeProduct(marca);
  }
}
