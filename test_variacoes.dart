import 'lib/services/brasileiridade_algorithm.dart';

void main() {
  print('=== TESTE DE VARIAÇÕES DE MARCA ===');

  // Teste com "Coca-cola" (hífen minúsculo)
  print('\nTeste 1: "Coca-cola"');
  final variacoes1 = BrasileiridadeAlgorithm.testarVariacoesMarca('Coca-cola');
  for (var variacao in variacoes1) {
    print('  - "$variacao"');
  }

  // Teste com "coca cola" (espaço minúsculo)
  print('\nTeste 2: "coca cola"');
  final variacoes2 = BrasileiridadeAlgorithm.testarVariacoesMarca('coca cola');
  for (var variacao in variacoes2) {
    print('  - "$variacao"');
  }

  // Teste com "nestle" (simples)
  print('\nTeste 3: "nestle"');
  final variacoes3 = BrasileiridadeAlgorithm.testarVariacoesMarca('nestle');
  for (var variacao in variacoes3) {
    print('  - "$variacao"');
  }

  // Verificar se "Coca-Cola" está nas variações de "Coca-cola"
  print('\n=== VERIFICAÇÃO ===');
  if (variacoes1.contains('Coca-Cola')) {
    print('✅ "Coca-Cola" encontrado nas variações de "Coca-cola"');
  } else {
    print('❌ "Coca-Cola" NÃO encontrado nas variações de "Coca-cola"');
  }
}
