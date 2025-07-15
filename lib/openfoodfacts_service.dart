import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';
  static const String _userAgent = 'CompreBrasil/1.0 (vrpedrinho@gmail.com)';

  /// Busca informações otimizadas do produto para exibição
  static Future<Map<String, dynamic>?> getProductInfo(String barcode) async {
    try {
      final url = '$_baseUrl/$barcode.json';
      print('Fazendo requisição otimizada para: $url');

      // Campos específicos para exibição na interface (apenas os necessários)
      final fields = [
        'product_name', // Nome do produto
        'brands', // Marca
        'countries', // Países
        'selected_images', // Imagens selecionadas
        'image_front_url', // Imagem frontal (fallback)
        'image_url', // Imagem geral (fallback)
        'image_packaging_url', // Imagem da embalagem (fallback)
      ].join(',');

      final uri = Uri.parse(url).replace(queryParameters: {'fields': fields});

      print('Campos solicitados: $fields');

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
          'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
        },
      );

      print('Status da resposta: ${response.statusCode}');
      print('Tamanho da resposta: ${response.body.length} bytes');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Produto encontrado: ${data['status'] == 1 ? 'Sim' : 'Não'}');

        if (data['product'] != null) {
          final product = data['product'];
          print('Nome do produto: ${product['product_name'] ?? 'N/A'}');
          print('Marca: ${product['brands'] ?? 'N/A'}');
          print('Países: ${product['countries'] ?? 'N/A'}');
        }

        return data;
      } else {
        print('Erro na requisição: ${response.statusCode}');
        print('Corpo da resposta: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erro ao buscar produto: $e');
      return null;
    }
  }

  /// Busca informações completas do produto para o JSON expandido
  static Future<Map<String, dynamic>?> getProductInfoComplete(String barcode) async {
    try {
      final url = '$_baseUrl/$barcode.json';
      print('Fazendo requisição completa para: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
          'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
        },
      );

      print('Status da resposta completa: ${response.statusCode}');
      print('Tamanho da resposta completa: ${response.body.length} bytes');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Dados completos obtidos: ${data['status'] == 1 ? 'Sim' : 'Não'}');
        return data;
      } else {
        print('Erro na requisição completa: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erro ao buscar dados completos: $e');
      return null;
    }
  }
}
