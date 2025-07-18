import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'barcode_result_page.dart';
import 'brand_search_result_page.dart';
import 'developer_options.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isValidInput = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_validateInput);
  }

  @override
  void dispose() {
    _searchController.removeListener(_validateInput);
    _searchController.dispose();
    super.dispose();
  }

  void _validateInput() {
    final text = _searchController.text.trim();
    // Aceita códigos de barras (8-14 dígitos), códigos FAKE para teste, ou nomes de marca/produto (mínimo 2 caracteres)
    final isValid =
        RegExp(r'^\d{8,14}$').hasMatch(text) ||
        text.startsWith('FAKE') ||
        (text.isNotEmpty && text.length >= 2 && !RegExp(r'^\d+$').hasMatch(text));

    if (_isValidInput != isValid) {
      setState(() {
        _isValidInput = isValid;
      });
    }
  }

  bool _isBarcode(String value) {
    return RegExp(r'^\d{8,14}$').hasMatch(value) || value.startsWith('FAKE');
  }

  void _searchProduct() {
    if (_isValidInput) {
      final searchText = _searchController.text.trim();

      if (_isBarcode(searchText)) {
        // Busca por código de barras - vai para a página tradicional
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BarcodeResultPage(barcodeResult: searchText)),
        );
      } else {
        // Busca por marca/nome do produto - vai direto para análise
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BrandSearchResultPage(brandName: searchText)),
        );
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesquisar Produto'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.search, color: Theme.of(context).colorScheme.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Digite o Código ou Nome da Marca',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _searchController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'Código de Barras ou Nome da Marca',
                        hintText: 'Ex: 7891000053508 ou Nestlé',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch)
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      onSubmitted: (_) => _searchProduct(),
                    ),
                    const SizedBox(height: 16),
                    if (_searchController.text.isNotEmpty && !_isValidInput)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Digite um código válido (8-14 números) ou nome da marca/produto (mín. 2 caracteres)',
                                style: TextStyle(color: Colors.orange[700], fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isValidInput
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isValidInput ? _searchProduct : null,
                        icon: const Icon(Icons.search),
                        label: const Text(
                          'Buscar Produto',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (DeveloperOptions.showTestCodes)
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Códigos para Teste',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView(
                            children: [
                              _buildTestCode('7891000053508', 'Nescau (Nestlé Brasil)'),
                              const SizedBox(height: 8),
                              _buildTestCode('7891000100103', 'Leite Ninho (Nestlé Brasil)'),
                              const SizedBox(height: 8),
                              _buildTestCode('7894900010015', 'Coca-Cola (Brasil)'),
                              const SizedBox(height: 8),
                              _buildTestCode('7898943163059', 'Atum Robson Crusoé (Brasil)'),
                              const SizedBox(height: 8),

                              // Produtos FAKE para teste das classificações
                              _buildTestCode('FAKE100', 'Produto FAKE - 100% Brasileiro'),
                              const SizedBox(height: 8),
                              _buildTestCode('FAKE75', 'Produto FAKE - 75% Brasileiro'),
                              const SizedBox(height: 8),
                              _buildTestCode('FAKE50', 'Produto FAKE - 50% Brasileiro'),
                              const SizedBox(height: 8),
                              _buildTestCode('FAKE30', 'Produto FAKE - 30% Brasileiro'),
                              const SizedBox(height: 8),
                              _buildTestCode('FAKE15', 'Produto FAKE - 15% Brasileiro'),
                              const SizedBox(height: 8),
                              _buildTestCode('FAKE0', 'Produto FAKE - 0% Brasileiro'),
                              const SizedBox(height: 8),
                              _buildTestCode('FAKEUSA', 'Produto FAKE - EUA'),
                              const SizedBox(height: 8),

                              _buildTestCode('3017620422003', 'Nutella (Ferrero França)'),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!DeveloperOptions.showTestCodes) const Expanded(child: SizedBox()),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.home),
              label: const Text('Voltar ao Início', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestCode(String code, String description) {
    return InkWell(
      onTap: () {
        _searchController.text = code;
        // Navegar diretamente para a página de resultados
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BarcodeResultPage(barcodeResult: code)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.touch_app,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
