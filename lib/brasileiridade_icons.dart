import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Classe para gerenciar ícones de brasileiridade
class BrasileiridadeIcons {
  /// Retorna o ícone apropriado baseado no grau de brasileiridade
  static Widget getIconForGrau(int grau) {
    if (grau >= 85) {
      return CountryFlag.fromCountryCode('BR', height: 20, width: 20);
    } else if (grau >= 65) {
      return const Icon(Icons.star, color: Colors.green, size: 20);
    } else if (grau >= 45) {
      return const Icon(Icons.star_half, color: Colors.orange, size: 20);
    } else if (grau >= 25) {
      return const Icon(Icons.star_border, color: Colors.deepOrange, size: 20);
    } else if (grau > 0) {
      return const Icon(Icons.error_outline, color: Colors.red, size: 20);
    } else {
      return const Icon(Icons.language, color: Colors.grey, size: 20);
    }
  }

  /// Retorna o ícone de status para logs
  static Widget getStatusIcon(String status) {
    switch (status) {
      case 'OK':
        return const Icon(Icons.check_circle, color: Colors.green, size: 16);
      case 'ERRO':
        return const Icon(Icons.error, color: Colors.red, size: 16);
      case 'AVISO':
        return const Icon(Icons.warning, color: Colors.orange, size: 16);
      case 'BUSCA':
        return const Icon(Icons.search, color: Colors.blue, size: 16);
      case 'DADOS':
        return const Icon(Icons.bar_chart, color: Colors.blue, size: 16);
      case 'LOCAL':
        return const Icon(Icons.location_on, color: Colors.purple, size: 16);
      case 'MELHOR':
        return const Icon(Icons.emoji_events, color: Colors.amber, size: 16);
      case '?':
        return const Icon(Icons.help_outline, color: Colors.grey, size: 16);
      default:
        return const Icon(Icons.info, color: Colors.grey, size: 16);
    }
  }

  /// Retorna o widget de bandeira para um país
  static Widget getFlagWidget(String country) {
    switch (country.toLowerCase()) {
      case 'brasil':
      case 'brazil':
        return CountryFlag.fromCountryCode('BR', height: 20, width: 20);
      case 'estados unidos':
      case 'united states':
      case 'usa':
        return CountryFlag.fromCountryCode('US', height: 20, width: 20);
      case 'argentina':
        return CountryFlag.fromCountryCode('AR', height: 20, width: 20);
      case 'frança':
      case 'france':
        return CountryFlag.fromCountryCode('FR', height: 20, width: 20);
      case 'méxico':
      case 'mexico':
        return CountryFlag.fromCountryCode('MX', height: 20, width: 20);
      case 'chile':
        return CountryFlag.fromCountryCode('CL', height: 20, width: 20);
      case 'espanha':
      case 'spain':
        return CountryFlag.fromCountryCode('ES', height: 20, width: 20);
      case 'canadá':
      case 'canada':
        return CountryFlag.fromCountryCode('CA', height: 20, width: 20);
      default:
        return const Icon(Icons.flag, size: 20, color: Colors.grey);
    }
  }

  /// Retorna o IconData do Material Design para usar no barcode_result_page
  static IconData getIconData(String type) {
    switch (type) {
      case 'BR':
        return Icons.flag; // Ícone de bandeira do Material Design
      case 'ALTO':
        return Icons.star;
      case 'MEDIO':
        return Icons.star_half;
      case 'BAIXO':
        return Icons.star_border;
      case 'MIN':
        return Icons.error_outline;
      case 'EST':
        return Icons.language;
      case 'OK':
        return Icons.check_circle;
      case 'ERRO':
        return Icons.error;
      case 'AVISO':
        return Icons.warning;
      case 'BUSCA':
        return Icons.search;
      case 'DADOS':
        return Icons.bar_chart;
      case 'LOCAL':
        return Icons.location_on;
      case 'MELHOR':
        return Icons.emoji_events;
      case '?':
        return Icons.help_outline;
      default:
        return Icons.info;
    }
  }
}
