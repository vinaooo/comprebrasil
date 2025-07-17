import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';
  static const String _userAgent = 'CompreBrasil/1.0 (vrpedrinho@gmail.com)';

  /// Busca informações otimizadas do produto para exibição
  static Future<Map<String, dynamic>?> getProductInfo(String barcode) async {
    // Verifica se é um produto FAKE para teste
    if (barcode.startsWith('FAKE')) {
      return _getFakeProductData(barcode);
    }

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
        // Campos adicionais para análise de brasileiridade
        'manufacturing_places', // Locais de fabricação
        'origins', // Origem dos ingredientes
        'countries_tags', // Tags de países
        'made_in', // País de fabricação
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
    // Verifica se é um produto FAKE para teste
    if (barcode.startsWith('FAKE')) {
      return _getFakeProductData(barcode);
    }

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

  /// Retorna dados fictícios para produtos de teste
  static Map<String, dynamic> _getFakeProductData(String barcode) {
    final fakeProducts = {
      'FAKE100': {
        'status': 1,
        'product': {
          'product_name': '[TESTE] Produto 100% Brasileiro',
          'brands': 'Marca Brasileira LTDA',
          'countries': 'Brasil',
          'manufacturing_places': 'São Paulo, Brasil',
          'origins': 'Ingredientes do Brasil',
          'countries_tags': ['en:brazil', 'pt:brasil'],
          'made_in': 'Brasil',
          'image_front_url':
              'https://via.placeholder.com/200x200/009639/FFFFFF?text=FAKE+100%25+BR',
          'selected_images': {
            'front': {
              'display': {
                'pt': 'https://via.placeholder.com/200x200/009639/FFFFFF?text=FAKE+100%25+BR',
              },
            },
          },
        },
      },
      'FAKE75': {
        'status': 1,
        'product': {
          'product_name': '[TESTE] Produto 75% Brasileiro',
          'brands': 'Empresa Majoritariamente Brasileira',
          'countries': 'Brasil, Argentina',
          'manufacturing_places': 'Rio de Janeiro, Brasil',
          'origins': 'Ingredientes Brasileiros e Importados',
          'countries_tags': ['en:brazil', 'en:argentina'],
          'made_in': 'Brasil',
          'image_front_url': 'https://via.placeholder.com/200x200/4CAF50/FFFFFF?text=FAKE+75%25+BR',
          'selected_images': {
            'front': {
              'display': {
                'pt': 'https://via.placeholder.com/200x200/4CAF50/FFFFFF?text=FAKE+75%25+BR',
              },
            },
          },
        },
      },
      'FAKE50': {
        'status': 1,
        'product': {
          'product_name': '[TESTE] Produto 50% Brasileiro',
          'brands': 'Empresa Parcialmente Brasileira',
          'countries': 'Brasil, Argentina',
          'manufacturing_places': 'Argentina',
          'origins': 'Ingredientes Mistos',
          'countries_tags': ['en:brazil', 'en:argentina'],
          'made_in': 'Brasil',
          'image_front_url': 'https://via.placeholder.com/200x200/FFC107/000000?text=FAKE+50%25+BR',
          'selected_images': {
            'front': {
              'display': {
                'pt': 'https://via.placeholder.com/200x200/FFC107/000000?text=FAKE+50%25+BR',
              },
            },
          },
        },
      },
      'FAKE30': {
        'status': 1,
        'product': {
          'product_name': '[TESTE] Produto 30% Brasileiro',
          'brands': 'Empresa Pouco Brasileira',
          'countries': 'México, Brasil',
          'manufacturing_places': 'México',
          'origins': 'Ingredientes Importados',
          'countries_tags': ['en:mexico', 'en:brazil'],
          'made_in': 'México',
          'image_front_url': 'https://via.placeholder.com/200x200/FF9800/FFFFFF?text=FAKE+30%25+BR',
          'selected_images': {
            'front': {
              'display': {
                'pt': 'https://via.placeholder.com/200x200/FF9800/FFFFFF?text=FAKE+30%25+BR',
              },
            },
          },
        },
      },
      'FAKE15': {
        'status': 1,
        'product': {
          'product_name': '[TESTE] Produto 15% Brasileiro',
          'brands': 'Empresa Minimamente Brasileira',
          'countries': 'Chile',
          'manufacturing_places': 'Chile',
          'origins': 'Ingredientes Chilenos',
          'countries_tags': ['en:chile'],
          'made_in': 'Chile',
          'image_front_url': 'https://via.placeholder.com/200x200/FF5722/FFFFFF?text=FAKE+15%25+BR',
          'selected_images': {
            'front': {
              'display': {
                'pt': 'https://via.placeholder.com/200x200/FF5722/FFFFFF?text=FAKE+15%25+BR',
              },
            },
          },
        },
      },
      'FAKE0': {
        'status': 1,
        'product': {
          'product_name': '[TESTE] Produto 0% Brasileiro',
          'brands': 'Marca Estrangeira Internacional',
          'countries': 'França',
          'manufacturing_places': 'França',
          'origins': 'Ingredientes Franceses',
          'countries_tags': ['en:france'],
          'made_in': 'França',
          'image_front_url': 'https://via.placeholder.com/200x200/607D8B/FFFFFF?text=FAKE+0%25+BR',
          'selected_images': {
            'front': {
              'display': {
                'pt': 'https://via.placeholder.com/200x200/607D8B/FFFFFF?text=FAKE+0%25+BR',
              },
            },
          },
        },
      },
      'FAKEUSA': {
        'status': 1,
        'product': {
          'product_name': '[TESTE] Produto Americano',
          'brands': 'American Corporation',
          'countries': 'Estados Unidos',
          'manufacturing_places': 'California, Estados Unidos',
          'origins': 'Ingredientes Americanos',
          'countries_tags': ['en:united-states'],
          'made_in': 'Estados Unidos',
          'image_front_url': 'https://via.placeholder.com/200x200/FF6B6B/FFFFFF?text=FAKE+USA',
          'selected_images': {
            'front': {
              'display': {'pt': 'https://via.placeholder.com/200x200/FF6B6B/FFFFFF?text=FAKE+USA'},
            },
          },
        },
      },
    };

    return fakeProducts[barcode] ?? {'status': 0, 'product': null};
  }
}
