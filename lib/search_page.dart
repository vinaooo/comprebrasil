import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'barcode_result_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isValidBarcode = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_validateBarcode);
  }

  @override
  void dispose() {
    _searchController.removeListener(_validateBarcode);
    _searchController.dispose();
    super.dispose();
  }

  void _validateBarcode() {
    final text = _searchController.text.trim();
    // Verificar se é um código de barras válido (apenas números, 8-14 dígitos)
    final isValid = RegExp(r'^\d{8,14}$').hasMatch(text);

    if (_isValidBarcode != isValid) {
      setState(() {
        _isValidBarcode = isValid;
      });
    }
  }

  void _searchProduct() {
    if (_isValidBarcode) {
      final barcode = _searchController.text.trim();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BarcodeResultPage(barcodeResult: barcode)),
      );
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
                          'Digite o Código de Barras',
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
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(14),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Código de Barras',
                        hintText: 'Ex: 7891000053508',
                        prefixIcon: const Icon(Icons.barcode_reader),
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
                    if (_searchController.text.isNotEmpty && !_isValidBarcode)
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
                                'Digite um código válido (8-14 números)',
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
                          backgroundColor: _isValidBarcode
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isValidBarcode ? _searchProduct : null,
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
            const SizedBox(height: 16),
            SizedBox(
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
          ],
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
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.touch_app, size: 20, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }
}
