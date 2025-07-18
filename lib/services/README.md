# Algoritmo de Brasileiridade - Estrutura de Código

## Separação de Responsabilidades

O código do algoritmo de brasileiridade foi reestruturado para separar claramente o algoritmo principal dos dados de teste, seguindo as melhores práticas de organização de código.

## Estrutura de Arquivos

### `lib/services/brasileiridade_service.dart`
**SERVIÇO PRINCIPAL**
- Ponto de entrada único para toda a aplicação
- Roteamento automático entre algoritmo principal e dados de teste
- Interface unificada para o resto da aplicação
- Funções de utilidade (temEnvolvimentoAmericano, eProdutoBrasileiro, etc.)

### `lib/services/brasileiridade_algorithm.dart`
**ALGORITMO PRINCIPAL**
- Contém SOMENTE o algoritmo puro de brasileiridade
- Análise real via Wikidata e OpenFoodFacts
- Algoritmo de cálculo de pontuação (40% matriz, 30% local, 20% fabricação, 10% origem)
- Classificação em categorias (BR, STAR, WARNING, WORLD)
- Classe `AnaliseResult` com todos os dados de resultado

### `lib/services/brasileiridade_test_data.dart`
**DADOS DE TESTE**
- Contém SOMENTE os dados fictícios para teste
- Produtos FAKE com resultados pré-definidos
- Isolamento completo dos dados de produção
- Facilita manutenção e debugging dos testes

## Funcionamento

### Fluxo de Execução
1. **Aplicação chama** → `BrasileiridadeService.analisarBrasileiridade(marca)`
2. **Serviço verifica** → Se é produto FAKE ou real
3. **Roteamento automático**:
   - **Produto FAKE** → `BrasileiridadeTestData.getFakeAnalysisResult()`
   - **Produto Real** → `BrasileiridadeAlgorithm.analisarBrasileiridade()`
4. **Retorno unificado** → `AnaliseResult` com dados completos

### Detecção de Produtos FAKE
```dart
// Automática - produtos que contêm:
- "FAKE" (qualquer variação)
- Nomes das empresas fictícias
- Códigos específicos (FAKE100, FAKE75, etc.)
```

## Vantagens da Nova Estrutura

### ✅ **Separação Clara**
- Algoritmo principal limpo, sem código de teste
- Dados de teste isolados e organizados
- Fácil manutenção e compreensão

### ✅ **Flexibilidade**
- Fácil adição de novos produtos de teste
- Modificação do algoritmo sem afetar testes
- Interface consistente para toda aplicação

### ✅ **Organização**
- Código mais legível e profissional
- Responsabilidades bem definidas
- Estrutura escalável para futuras expansões

### ✅ **Reutilização**
- Algoritmo pode ser usado independentemente
- Dados de teste centralizados
- Funções de utilidade acessíveis

## Uso na Aplicação

### Importação
```dart
import 'services/brasileiridade_service.dart';
```

### Análise de Produto
```dart
// Funciona tanto para produtos reais quanto FAKE
final resultado = await BrasileiridadeService.analisarBrasileiridade(marca);
```

### Funções de Utilidade
```dart
// Verificar se é brasileiro (≥65%)
bool eBrasileiro = BrasileiridadeService.eProdutoBrasileiro(resultado);

// Detectar envolvimento americano
bool temEUA = BrasileiridadeService.temEnvolvimentoAmericano(resultado);

// Verificar se é produto de teste
bool eFake = BrasileiridadeService.isFakeProduct(marca);
```

## Migração

A migração foi realizada mantendo **100% de compatibilidade** com o código existente:
- Todas as funções públicas mantidas
- Interface idêntica para a aplicação
- Zero mudanças necessárias no código cliente

## Produtos de Teste Disponíveis

| Código | Empresa | Grau | Classificação |
|--------|---------|------|---------------|
| FAKE100 | Marca Brasileira LTDA | 90-100% | BR Totalmente Brasileira |
| FAKE75 | Empresa Majoritariamente Brasileira | 75% | STAR Majoritariamente Brasileira |
| FAKE50 | Empresa Parcialmente Brasileira | 50% | STAR Parcialmente Brasileira |
| FAKE30 | Empresa Pouco Brasileira | 30% | STAR Pouco Brasileira |
| FAKE15 | Empresa Minimamente Brasileira | 15% | WARNING Minimamente Brasileira |
| FAKE0 | Marca Estrangeira Internacional | 0% | WORLD Marca Estrangeira |
| FAKEUSA | American Corporation | 0% | WORLD Marca Estrangeira |

Esta estrutura garante que o **algoritmo principal permanece puro e focado**, enquanto os **dados de teste estão organizados e isolados**, resultando em código mais limpo, manutenível e profissional.
