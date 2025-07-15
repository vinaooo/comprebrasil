import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'barcode_result_page.dart';

class ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const ScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.5),
    this.borderRadius = 12,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;

    final cutOutWidth = cutOutSize;
    final cutOutHeight = cutOutSize;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - cutOutWidth / 2,
      rect.top + height / 2 - cutOutHeight / 2,
      cutOutWidth,
      cutOutHeight,
    );

    final cutOutRRect = RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius));

    final overlayPath = Path()
      ..addRect(rect)
      ..addRRect(cutOutRRect)
      ..fillType = PathFillType.evenOdd;

    return overlayPath;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;

    final cutOutWidth = cutOutSize;
    final cutOutHeight = cutOutSize;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - cutOutWidth / 2,
      rect.top + height / 2 - cutOutHeight / 2,
      cutOutWidth,
      cutOutHeight,
    );

    final cutOutRRect = RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius));

    // Desenhar o overlay escuro
    final overlayPath = Path()
      ..addRect(rect)
      ..addRRect(cutOutRRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, Paint()..color = overlayColor);

    // Desenhar as bordas dos cantos
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path();

    // Canto superior esquerdo
    path.moveTo(cutOutRect.left, cutOutRect.top + borderLength);
    path.lineTo(cutOutRect.left, cutOutRect.top + borderRadius);
    path.arcToPoint(
      Offset(cutOutRect.left + borderRadius, cutOutRect.top),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(cutOutRect.left + borderLength, cutOutRect.top);

    // Canto superior direito
    path.moveTo(cutOutRect.right - borderLength, cutOutRect.top);
    path.lineTo(cutOutRect.right - borderRadius, cutOutRect.top);
    path.arcToPoint(
      Offset(cutOutRect.right, cutOutRect.top + borderRadius),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(cutOutRect.right, cutOutRect.top + borderLength);

    // Canto inferior direito
    path.moveTo(cutOutRect.right, cutOutRect.bottom - borderLength);
    path.lineTo(cutOutRect.right, cutOutRect.bottom - borderRadius);
    path.arcToPoint(
      Offset(cutOutRect.right - borderRadius, cutOutRect.bottom),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(cutOutRect.right - borderLength, cutOutRect.bottom);

    // Canto inferior esquerdo
    path.moveTo(cutOutRect.left + borderLength, cutOutRect.bottom);
    path.lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom);
    path.arcToPoint(
      Offset(cutOutRect.left, cutOutRect.bottom - borderRadius),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(cutOutRect.left, cutOutRect.bottom - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return ScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
      borderRadius: borderRadius,
    );
  }
}

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({Key? key}) : super(key: key);

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool _canScan = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner de Código de Barras'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    if (!_canScan) return;

                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        setState(() {
                          _canScan = false;
                        });
                        _showBarcodeResult(barcode.rawValue!);
                        break;
                      }
                    }
                  },
                ),
                // Overlay com quadrado de escaneamento
                Container(
                  decoration: ShapeDecoration(
                    shape: ScannerOverlayShape(
                      borderColor: Theme.of(context).colorScheme.primary,
                      borderWidth: 3,
                      overlayColor: Colors.black.withOpacity(0.5),
                      borderRadius: 12,
                      borderLength: 40,
                      cutOutSize: MediaQuery.of(context).size.width * 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: Text(
                  'Posicione o código de barras na área de escaneamento',
                  style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBarcodeResult(String result) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BarcodeResultPage(barcodeResult: result)),
    );

    // Reativar o scanner quando voltar da tela de resultado
    setState(() {
      _canScan = true;
    });
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
