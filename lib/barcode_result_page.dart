import 'dart:convert';
import 'package:flutter/material.dart';
import 'openfoodfacts_service.dart';
import 'brasileiridade_service.dart';

class BarcodeResultPage extends StatefulWidget {
  final String barcodeResult;

  const BarcodeResultPage({Key? key, required this.barcodeResult}) : super(key: key);

  @override
  State<BarcodeResultPage> createState() => _BarcodeResultPageState();
}

class _BarcodeResultPageState extends State<BarcodeResultPage> {
  Map<String, dynamic>? productData;
  Map<String, dynamic>? completeProductData;
  AnaliseResult? analiseResultado;
  bool isLoading = true;
  bool isLoadingComplete = false;
  bool isLoadingAnalise = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProductData();
  }

  Future<void> _fetchProductData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await OpenFoodFactsService.getProductInfo(widget.barcodeResult);
      setState(() {
        productData = data;
        isLoading = false;
      });

      // Analisa brasileiridade da marca após carregar os dados do produto
      if (data != null && data['product'] != null && data['product']['brands'] != null) {
        _analisarBrasileiridade(data['product']['brands']);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erro ao buscar informações do produto: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _analisarBrasileiridade(String marcas) async {
    setState(() {
      isLoadingAnalise = true;
    });

    try {
      // Analisa múltiplas marcas e retorna a com maior grau de brasileiridade
      final analise = await BrasileiridadeService.analisarMultiplasMarcas(marcas);

      setState(() {
        analiseResultado = analise;
        isLoadingAnalise = false;
      });
    } catch (e) {
      setState(() {
        isLoadingAnalise = false;
      });
      print('Erro ao analisar brasileiridade: $e');
    }
  }

  Future<void> _fetchCompleteProductData() async {
    if (completeProductData != null) return; // Já carregado

    setState(() {
      isLoadingComplete = true;
    });

    try {
      final data = await OpenFoodFactsService.getProductInfoComplete(widget.barcodeResult);
      setState(() {
        completeProductData = data;
        isLoadingComplete = false;
      });
    } catch (e) {
      setState(() {
        isLoadingComplete = false;
      });
      print('Erro ao carregar dados completos: $e');
    }
  }

  Widget _buildProductInfo() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Buscando informações do produto...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(errorMessage!, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchProductData, child: const Text('Tentar Novamente')),
          ],
        ),
      );
    }

    if (productData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma informação encontrada para este produto.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (productData!['status'] == 1 && productData!['product'] != null)
            _buildProductDetails(productData!['product'])
          else
            _buildRawData(),
        ],
      ),
    );
  }

  Widget _buildProductDetails(Map<String, dynamic> product) {
    final isBrazilian =
        product['countries'] != null &&
        (product['countries'].toLowerCase().contains('brazil') ||
            product['countries'].toLowerCase().contains('brasil'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner brasileiro (se aplicável)
        if (isBrazilian) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF009639), const Color(0xFF00B142)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF009639).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text('🇧🇷', style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PRODUTO BRASILEIRO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Apoie a economia nacional! 💚',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.verified, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Imagem do produto
        _buildProductImage(product),
        const SizedBox(height: 16),

        if (product['product_name'] != null) ...[
          _buildInfoRow('Nome', product['product_name']),
          const SizedBox(height: 12),
        ],
        if (product['brands'] != null) ...[
          _buildInfoRow('Marca', product['brands']),
          const SizedBox(height: 12),
        ],
        // Análise de brasileiridade
        if (product['brands'] != null) ...[
          _buildBrasileiridadeAnalise(),
          const SizedBox(height: 12),
        ],
        if (product['countries'] != null) ...[
          _buildCountriesRow('Países', product['countries']),
          const SizedBox(height: 12),
        ],
        const Divider(height: 32),
        ExpansionTile(
          title: const Text(
            'Dados Completos (JSON)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onExpansionChanged: (isExpanded) {
            if (isExpanded) {
              _fetchCompleteProductData();
            }
          },
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: isLoadingComplete
                  ? const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Carregando dados completos...', style: TextStyle(fontSize: 12)),
                      ],
                    )
                  : SelectableText(
                      _formatJson(completeProductData ?? productData!),
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRawData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dados brutos da API:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: SelectableText(
            _formatJson(productData!),
            style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCountriesRow(String label, String value) {
    final isBrazilian =
        value.toLowerCase().contains('brazil') || value.toLowerCase().contains('brasil');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            if (isBrazilian) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF009639),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🇧🇷', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      'PRODUTO BRASILEIRO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isBrazilian ? const Color(0xFFE8F5E8) : Colors.grey[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isBrazilian ? const Color(0xFF009639) : Colors.grey[200]!,
              width: isBrazilian ? 2 : 1,
            ),
          ),
          child: SelectableText(
            value,
            style: TextStyle(
              fontSize: 14,
              color: isBrazilian ? const Color(0xFF006B2F) : null,
              fontWeight: isBrazilian ? FontWeight.w500 : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: SelectableText(value, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildBrasileiridadeAnalise() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, size: 16, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Text(
              'Análise de Brasileiridade',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: isLoadingAnalise
              ? const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Analisando brasileiridade da marca...'),
                  ],
                )
              : analiseResultado == null
              ? const Text('Análise não disponível')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (analiseResultado!.semDados) ...[
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.orange[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Dados insuficientes para análise',
                              style: TextStyle(color: Colors.orange[600]),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Grau de brasileiridade
                      Row(
                        children: [
                          Text(
                            'Grau: ${analiseResultado!.grauBrasileiridade}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: (analiseResultado!.grauBrasileiridade ?? 0) / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getCorBrasileiridade(analiseResultado!.grauBrasileiridade ?? 0),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Classificação
                      Text(
                        analiseResultado!.classificacao,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      // Detalhes expandíveis
                      if (analiseResultado!.detalhes.isNotEmpty) ...[
                        ExpansionTile(
                          title: const Text(
                            'Ver detalhes da análise',
                            style: TextStyle(fontSize: 12),
                          ),
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(top: 8),
                          children: [
                            ...analiseResultado!.detalhes.map(
                              (detalhe) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ', style: TextStyle(fontSize: 12)),
                                    Expanded(
                                      child: Text(detalhe, style: const TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Color _getCorBrasileiridade(int grau) {
    if (grau >= 85) return const Color(0xFF009639); // Verde Brasil
    if (grau >= 65) return Colors.green;
    if (grau >= 45) return Colors.orange;
    if (grau >= 25) return Colors.deepOrange;
    return Colors.red;
  }

  Widget _buildProductImage(Map<String, dynamic> product) {
    String? imageUrl;

    // Prioridade das imagens:
    // 1. Imagem frontal (front)
    // 2. Imagem geral (image_front_url)
    // 3. Imagem de embalagem (packaging)
    // 4. Qualquer imagem disponível

    if (product['selected_images'] != null) {
      final selectedImages = product['selected_images'];

      // Tentar imagem frontal primeiro
      if (selectedImages['front'] != null && selectedImages['front']['display'] != null) {
        final frontDisplay = selectedImages['front']['display'];
        imageUrl = frontDisplay['pt'] ?? frontDisplay.values.first;
      }

      // Se não tiver frontal, tentar packaging
      if (imageUrl == null &&
          selectedImages['packaging'] != null &&
          selectedImages['packaging']['display'] != null) {
        final packagingDisplay = selectedImages['packaging']['display'];
        imageUrl = packagingDisplay['pt'] ?? packagingDisplay.values.first;
      }
    }

    // Se não encontrou nas selected_images, tentar image_front_url diretamente
    if (imageUrl == null) {
      imageUrl =
          product['image_front_url'] ?? product['image_url'] ?? product['image_packaging_url'];
    }

    if (imageUrl == null) {
      return Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('Imagem não disponível', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text('Carregando imagem...', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Erro ao carregar imagem',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatJson(Map<String, dynamic> data) {
    try {
      final encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (e) {
      return data.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Código Escaneado'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                            Icons.shopping_cart,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Informações do Produto',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(child: _buildProductInfo()),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Escanear Novamente'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Voltar ao Início'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
