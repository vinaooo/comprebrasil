import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'openfoodfacts_service.dart';
import 'services/brasileiridade_service.dart';
import 'developer_options.dart';

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

  // Controle para mostrar dados JSON
  int _tapCount = 0;
  bool _showJsonData = false;
  DateTime? _lastTapTime;

  void _handleTap() {
    if (!mounted) return;

    final now = DateTime.now();

    // Se passou mais de 2 segundos desde o último toque, resetar contador
    if (_lastTapTime == null || now.difference(_lastTapTime!).inSeconds > 2) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }

    _lastTapTime = now;

    // Se chegou a 7 toques, alternar visibilidade dos dados JSON
    if (_tapCount >= 7) {
      setState(() {
        _showJsonData = !_showJsonData;
        _tapCount = 0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchProductData();
  }

  Future<void> _fetchProductData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await OpenFoodFactsService.getProductInfo(widget.barcodeResult);

      if (!mounted) return;

      setState(() {
        productData = data;
        isLoading = false;
      });

      // Analisa brasileiridade da marca após carregar os dados do produto
      if (data != null && data['product'] != null && data['product']['brands'] != null) {
        _analisarBrasileiridade(data['product']['brands']);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Erro ao buscar informações do produto: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _analisarBrasileiridade(String marcas) async {
    if (!mounted) return;

    setState(() {
      isLoadingAnalise = true;
    });

    try {
      // Analisa múltiplas marcas e retorna a com maior grau de brasileiridade
      final analise = await BrasileiridadeService.analisarMultiplasMarcas(marcas);

      // Se há dados do produto, aplica análise OpenFoodFacts
      AnaliseResult analiseComplementada = analise;
      if (productData != null) {
        analiseComplementada = BrasileiridadeService.analisarDadosOpenFoodFacts(
          productData!,
          analise,
        );
      }

      if (!mounted) return;

      setState(() {
        analiseResultado = analiseComplementada;
        isLoadingAnalise = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingAnalise = false;
      });
      print('Erro ao analisar brasileiridade: $e');
    }
  }

  Future<void> _fetchCompleteProductData() async {
    if (completeProductData != null) return; // Já carregado
    if (!mounted) return;

    setState(() {
      isLoadingComplete = true;
    });

    try {
      final data = await OpenFoodFactsService.getProductInfoComplete(widget.barcodeResult);

      if (!mounted) return;

      setState(() {
        completeProductData = data;
        isLoadingComplete = false;
      });
    } catch (e) {
      if (!mounted) return;

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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'Nenhuma informação encontrada para este produto.',
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card de alerta no topo
        _buildAlertCard(),

        // Header compacto do produto (imagem, nome e marca)
        _buildProductHeader(product),
        const SizedBox(height: 16),

        // Análise de brasileiridade
        if (product['brands'] != null) ...[
          _buildBrasileiridadeAnalise(),
          const SizedBox(height: 12),
        ],
        const Divider(height: 32),
        if (_showJsonData || DeveloperOptions.showOpenFoodFactsJson)
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
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
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
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
          ),
          child: SelectableText(
            _formatJson(productData!),
            style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildProductHeader(Map<String, dynamic> product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Imagem do produto (compacta)
          _buildCompactProductImage(product),
          const SizedBox(width: 16),
          // Nome e marca
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product['product_name'] != null) ...[
                  Text(
                    'Nome',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['product_name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
                if (product['brands'] != null) ...[
                  Text(
                    'Marca',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['brands'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactProductImage(Map<String, dynamic> product) {
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
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 24,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 4),
            Text(
              'Sem imagem',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 80,
              height: 80,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 24,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Erro',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 10,
                    ),
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

  Widget _buildBrasileiridadeAnalise() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final blueColor = isDarkMode ? Colors.blue[300] : Colors.blue[600];
    final backgroundColor = isDarkMode ? Colors.blue[900]?.withValues(alpha: 0.2) : Colors.blue[50];
    final borderColor = isDarkMode ? Colors.blue[700]?.withValues(alpha: 0.5) : Colors.blue[200];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, size: 16, color: blueColor),
            const SizedBox(width: 8),
            Text(
              'Análise de Brasileiridade',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: blueColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _handleTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor ?? Colors.blue[200]!),
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
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.3),
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
                        // Detalhes sempre visíveis
                        if (analiseResultado!.detalhes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Detalhes da análise:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
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
                      ],
                    ],
                  ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shopping_cart, color: Theme.of(context).colorScheme.onPrimary, size: 20),
            const SizedBox(width: 8),
            const Text('Informações do Produto'),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Card(
                elevation: 2,
                child: Padding(padding: const EdgeInsets.all(16.0), child: _buildProductInfo()),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        ),
      ),
    );
  }

  /// Cria um card de alerta no topo da tela
  Widget _buildAlertCard() {
    if (analiseResultado == null || analiseResultado!.semDados) return const SizedBox.shrink();

    final temEUA = BrasileiridadeService.temEnvolvimentoAmericano(analiseResultado!);
    final grau = analiseResultado!.grauBrasileiridade ?? 0;

    // REGRA ESPECIAL: EUA sempre resulta em card vermelho
    if (temEUA) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B6B).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.flag, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ENVOLVIMENTO AMERICANO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    grau >= 65
                        ? 'Apesar da brasileiridade de ${grau}%, este produto tem ligação com os EUA'
                        : 'Este produto possui envolvimento com os Estados Unidos',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Classificação por porcentagem usando as cores definidas
    return _buildClassificationCard(grau);
  }

  Widget _buildClassificationCard(int grau) {
    Color primaryColor;
    Color secondaryColor;
    String title;
    String description;

    if (grau >= 85) {
      // 85-100%: Totalmente Brasileira
      primaryColor = const Color(0xFF009639);
      secondaryColor = const Color(0xFF00B142);
      title = 'TOTALMENTE BRASILEIRA';
      description =
          'Produto 100% brasileiro! Comprando você fortalece nossa economia. ${grau}% brasileira';
    } else if (grau >= 65) {
      // 65-84%: Majoritariamente Brasileira
      primaryColor = const Color(0xFF4CAF50);
      secondaryColor = const Color(0xFF66BB6A);
      title = 'MAJORITARIAMENTE BRASILEIRA';
      description = 'Produto com forte conexão brasileira! ${grau}% brasileira';
    } else if (grau >= 45) {
      // 45-64%: Parcialmente Brasileira
      primaryColor = const Color(0xFFFFC107);
      secondaryColor = const Color(0xFFFFD54F);
      title = 'PARCIALMENTE BRASILEIRA';
      description = 'Produto com conexão parcial ao Brasil. ${grau}% brasileira';
    } else if (grau >= 25) {
      // 25-44%: Pouco Brasileira
      primaryColor = const Color(0xFFFF9800);
      secondaryColor = const Color(0xFFFFB74D);
      title = 'POUCO BRASILEIRA';
      description = 'Produto com baixa conexão ao Brasil. ${grau}% brasileira';
    } else if (grau > 0) {
      // 1-24%: Minimamente Brasileira
      primaryColor = const Color(0xFFFF5722);
      secondaryColor = const Color(0xFFFF7043);
      title = 'MINIMAMENTE BRASILEIRA';
      description = 'Produto com conexão mínima ao Brasil. ${grau}% brasileira';
    } else {
      // 0%: Marca Estrangeira
      primaryColor = const Color(0xFF607D8B);
      secondaryColor = const Color(0xFF78909C);
      title = 'MARCA ESTRANGEIRA';
      description = 'Produto sem conexão identificada com o Brasil';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: grau >= 85
                ? CountryFlag.fromCountryCode('BR', height: 20, width: 20)
                : grau >= 65
                ? CountryFlag.fromCountryCode('BR', height: 20, width: 20)
                : grau >= 45
                ? const Icon(Icons.warning, color: Colors.white, size: 20)
                : grau >= 25
                ? const Icon(Icons.warning_amber, color: Colors.white, size: 20)
                : grau > 0
                ? const Icon(Icons.error_outline, color: Colors.white, size: 20)
                : const Icon(Icons.language, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
