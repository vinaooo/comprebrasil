import 'package:flutter/material.dart';
import 'barcode_scanner_page.dart';
import 'search_page.dart';
import 'developer_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DeveloperOptions.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CompreBrasil',
      // Tema claro - respeitando as cores da bandeira do Brasil
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF009639), // Verde Brasil
              brightness: Brightness.light,
            ).copyWith(
              primary: const Color(0xFF009639), // Verde Brasil
              secondary: const Color(0xFFFFCC00), // Amarelo Brasil
              tertiary: const Color(0xFF002776), // Azul Brasil
              surface: const Color(0xFFF8F9FA),
              onPrimary: Colors.white,
              onSecondary: const Color(0xFF1A1A1A),
              onSurface: const Color(0xFF1A1A1A),
            ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF009639),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(elevation: 2, shadowColor: Colors.black26),
        ),
      ),
      // Tema escuro - adaptando as cores da bandeira para o modo escuro
      darkTheme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF009639), // Verde Brasil
              brightness: Brightness.dark,
            ).copyWith(
              primary: const Color(0xFF00A63F), // Verde Brasil mais claro para contraste
              secondary: const Color(0xFFFFD700), // Amarelo Brasil mais claro
              tertiary: const Color(0xFF4A90E2), // Azul Brasil mais claro
              surface: const Color(0xFF1A1A1A),
              onPrimary: Colors.white,
              onSecondary: const Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00A63F),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(elevation: 2, shadowColor: Colors.black54),
        ),
      ),
      // Seguir o tema do sistema automaticamente
      themeMode: ThemeMode.system,
      home: const MyHomePage(title: 'Compre no Brasil'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConfiguracoesPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart,
                size: MediaQuery.of(context).size.width * 0.3,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              Text(
                'Compre Nacional, Fortaleça o Brasil',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.06,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.1),
                child: Text(
                  'Descubra produtos de empresas 100% brasileiras e gere empregos no nosso país',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                shape: const CircleBorder(),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
              },
              child: const Icon(Icons.search, size: 30),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                shape: const CircleBorder(),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
                );
              },
              child: const Icon(Icons.barcode_reader, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}

class ConfiguracoesPage extends StatelessWidget {
  const ConfiguracoesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacidade'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Implementar configurações de privacidade
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.developer_mode),
              title: const Text('Opções de Desenvolvedor'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DeveloperOptionsPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Sobre o App'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Implementar informações sobre o app
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DeveloperOptionsPage extends StatefulWidget {
  const DeveloperOptionsPage({super.key});

  @override
  State<DeveloperOptionsPage> createState() => _DeveloperOptionsPageState();
}

class _DeveloperOptionsPageState extends State<DeveloperOptionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opções de Desenvolvedor'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Opções de Debug',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Mostrar Códigos de Teste'),
                      subtitle: const Text(
                        'Exibe o quadro "Código para Testes" na página de pesquisa',
                      ),
                      value: DeveloperOptions.showTestCodes,
                      onChanged: (value) async {
                        await DeveloperOptions.setShowTestCodes(value ?? false);
                        setState(() {});
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Mostrar OpenFoodFacts JSON'),
                      subtitle: const Text('Exibe os dados JSON do OpenFoodFacts na análise'),
                      value: DeveloperOptions.showOpenFoodFactsJson,
                      onChanged: (value) async {
                        await DeveloperOptions.setShowOpenFoodFactsJson(value ?? false);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
