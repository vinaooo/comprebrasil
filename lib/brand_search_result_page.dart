import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'services/brasileiridade_service.dart';

class BrandSearchResultPage extends StatefulWidget {
  final String brandName;

  const BrandSearchResultPage({Key? key, required this.brandName}) : super(key: key);

  @override
  State<BrandSearchResultPage> createState() => _BrandSearchResultPageState();
}

class _BrandSearchResultPageState extends State<BrandSearchResultPage> {
  AnaliseResult? analiseResultado;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _searchBrand();
  }

  Future<void> _searchBrand() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final resultado = await BrasileiridadeService.analisarBrasileiridade(widget.brandName);

      if (mounted) {
        setState(() {
          analiseResultado = resultado;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Erro ao buscar informações da marca: $e';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Busca: ${widget.brandName}'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card com informações da busca
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.search, color: Theme.of(context).colorScheme.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Resultado da Busca',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Marca/Produto: ${widget.brandName}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Busca realizada na Wikidata',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Conteúdo principal
            if (isLoading)
              _buildLoadingCard()
            else if (errorMessage != null)
              _buildErrorCard()
            else if (analiseResultado != null)
              _buildAnalysisResult()
            else
              _buildNoResultCard(),
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
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Voltar', style: TextStyle(fontSize: 16)),
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
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  icon: const Icon(Icons.home),
                  label: const Text('Início', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Buscando informações na Wikidata...',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 48),
            const SizedBox(height: 16),
            Text(
              'Erro na Busca',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[600]),
            ),
            const SizedBox(height: 8),
            Text(errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _searchBrand,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum Resultado Encontrado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Não foi possível encontrar informações sobre "${widget.brandName}" na Wikidata.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResult() {
    if (analiseResultado == null) return const SizedBox();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com bandeira e título
            Row(
              children: [
                if (analiseResultado!.origem != null && analiseResultado!.origem!.isNotEmpty)
                  CountryFlag.fromCountryCode(
                    _getCountryCode(analiseResultado!.origem!),
                    height: 32,
                    width: 48,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analiseResultado!.marca,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (analiseResultado!.origem != null && analiseResultado!.origem!.isNotEmpty)
                        Text(
                          'Origem: ${analiseResultado!.origem!}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Grau de brasileiridade
            _buildBrasileiridadeCard(),

            const SizedBox(height: 16),

            // Detalhes da análise
            if (analiseResultado!.detalhes.isNotEmpty) ...[
              Text(
                'Detalhes da Análise:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              ...analiseResultado!.detalhes.map(
                (detalhe) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text('• $detalhe', style: const TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBrasileiridadeCard() {
    if (analiseResultado == null || analiseResultado!.grauBrasileiridade == null)
      return const SizedBox();

    final grau = analiseResultado!.grauBrasileiridade!;
    final Color corPrimaria;
    final Color corSecundaria;
    final String descricao;

    if (grau >= 80) {
      corPrimaria = const Color(0xFF006B3C); // Verde bandeira
      corSecundaria = const Color(0xFFE8F5E8);
      descricao = 'Altamente Brasileiro';
    } else if (grau >= 60) {
      corPrimaria = const Color(0xFF228B22);
      corSecundaria = const Color(0xFFE8F5E8);
      descricao = 'Predominantemente Brasileiro';
    } else if (grau >= 40) {
      corPrimaria = const Color(0xFFFEDF00); // Amarelo bandeira
      corSecundaria = const Color(0xFFFFFDF0);
      descricao = 'Parcialmente Brasileiro';
    } else if (grau >= 20) {
      corPrimaria = const Color(0xFFFF8C00);
      corSecundaria = const Color(0xFFFFF4E6);
      descricao = 'Baixa Brasileiridade';
    } else {
      corPrimaria = const Color(0xFFDC143C);
      corSecundaria = const Color(0xFFFFF0F0);
      descricao = 'Não Brasileiro';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: corSecundaria,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: corPrimaria.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Grau de Brasileiridade',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: corPrimaria),
          ),
          const SizedBox(height: 8),
          Text(
            '${grau.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: corPrimaria),
          ),
          const SizedBox(height: 4),
          Text(
            descricao,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: corPrimaria),
          ),
        ],
      ),
    );
  }

  String _getCountryCode(String country) {
    final countryMap = {
      'Brasil': 'BR',
      'Brazil': 'BR',
      'Estados Unidos': 'US',
      'United States': 'US',
      'França': 'FR',
      'France': 'FR',
      'Alemanha': 'DE',
      'Germany': 'DE',
      'Itália': 'IT',
      'Italy': 'IT',
      'Reino Unido': 'GB',
      'United Kingdom': 'GB',
      'Espanha': 'ES',
      'Spain': 'ES',
      'Japão': 'JP',
      'Japan': 'JP',
      'China': 'CN',
      'Coreia do Sul': 'KR',
      'South Korea': 'KR',
      'Canadá': 'CA',
      'Canada': 'CA',
      'México': 'MX',
      'Mexico': 'MX',
      'Argentina': 'AR',
      'Chile': 'CL',
      'Colômbia': 'CO',
      'Colombia': 'CO',
      'Peru': 'PE',
      'Uruguai': 'UY',
      'Uruguay': 'UY',
    };

    return countryMap[country] ?? 'UN'; // UN para países não mapeados
  }
}
