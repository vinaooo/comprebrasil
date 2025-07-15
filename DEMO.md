# CompreBrasil - Demo e Teste

## Códigos de Barras para Teste

Aqui estão alguns códigos de barras que você pode usar para testar o app:

### Produtos Brasileiros
- **7891000053508** - Nescau (Nestlé Brasil)
- **7891000100103** - Leite Ninho (Nestlé Brasil)
- **7891962000000** - Produtos Bauducco
- **7891000244234** - KitKat (Nestlé Brasil)

### Produtos Internacionais Conhecidos
- **3017620422003** - Nutella (Ferrero - França)
- **8712100849718** - Red Bull (Áustria)
- **4902777312132** - Ramen Nissin (Japão)
- **8901030873935** - Maggi (Índia)

### Como Testar

1. **Tela Inicial**: Verifique o tema das cores da bandeira do Brasil
2. **Botão Scanner**: Toque no botão com ícone de leitor de código
3. **Scanner**: Use a câmera para escanear ou digite um dos códigos acima
4. **Resultado**: Veja as informações detalhadas do produto da API OpenFoodFacts

### Funcionalidades Implementadas

✅ **Interface Brasileira**: Tema verde, amarelo e azul  
✅ **Scanner de Código**: Overlay centralizador e controle de flash  
✅ **API Integration**: Busca automática no OpenFoodFacts  
✅ **Exibição Completa**: Todos os dados do produto organizados  
✅ **Navegação Fluida**: Botões para escanear novamente ou voltar ao início  
✅ **Copiar Código**: Funcionalidade para copiar o código de barras  
✅ **Tratamento de Erros**: Loading, erro e estados vazios  

### Informações Exibidas

O app mostra as seguintes informações quando disponíveis:
- Nome do produto
- Marca
- Quantidade
- Categorias
- Países de origem
- Local de fabricação
- Lojas onde é vendido
- Ingredientes
- Alérgenos
- Nota nutricional (Nutri-Score)
- Dados completos em JSON (expandível)

### Dicas de Uso

- Para produtos brasileiros, verifique o campo "Países" para confirmar origem
- Use o botão de copiar para salvar códigos interessantes
- Os dados JSON completos contêm informações adicionais técnicas
- Produtos não cadastrados no OpenFoodFacts mostrarão apenas o código escaneado

### Próximos Passos Sugeridos

- Adicionar filtro específico para produtos brasileiros
- Implementar favoritos para produtos escaneados
- Adicionar histórico de escaneamentos
- Melhorar a interface para destacar empresas brasileiras
- Adicionar funcionalidade de pesquisa manual (botão da lupa)
