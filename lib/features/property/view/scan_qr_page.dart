import 'dart:async';

import 'package:easy_debounce/easy_debounce.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/app_extension.dart';
import 'package:patrol/core/utils/image_helper.dart';
import 'package:patrol/core/widgets/widgets.dart';
import 'package:patrol/service_locator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({super.key, this.showGalleryButton = true});

  final bool showGalleryButton;

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> with WidgetsBindingObserver {
  MobileScannerController? controller;

  final TextEditingController barcodeScannerController =
      TextEditingController();
  final FocusNode _bluetoothFocusNode = FocusNode();
  String _bluetoothBuffer = '';
  Timer? _bluetoothTimer;
  bool _isProcessingBluetoothInput = false;
  bool _isReturning = false;

  MobileScannerController initController() => MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    returnImage: true,
    autoZoom: false,
    formats: [BarcodeFormat.qrCode, BarcodeFormat.code128],
  );

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    controller = initController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bluetoothFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    controller?.dispose();
    controller = null;
    barcodeScannerController.dispose();
    _bluetoothFocusNode.dispose();
    _bluetoothTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        controller ??= initController();
        if (!controller!.value.isRunning && !controller!.value.isStarting) {
          controller?.start();
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _bluetoothFocusNode.requestFocus();
          }
        });
        return;
      case AppLifecycleState.inactive:
        controller?.stop();
    }
  }

  bool isScanning = true;

  Future<void> takeFromGallery() async {
    EasyThrottle.throttle(
      'take photo',
      const Duration(milliseconds: 500),
      () async {
        try {
          final XFile? image = await sl<ImageHelper>().pickImage();
          if (image == null) return;
          final result = await controller?.analyzeImage(image.path);
          if (result?.barcodes.isEmpty ?? false) {
            Fluttertoast.showToast(msg: "Invalid qr code");
          } else {
            Fluttertoast.showToast(msg: "code: ${result?.barcodes}");
            // _navigateToPrescription(result?.barcodes.first.rawValue);
          }
        } catch (e) {
          debugPrint(e.toString());
        }
      },
    );
  }

  void _returnCode(String code) {
    if (_isReturning) return;
    _isReturning = true;

    setState(() {
      isScanning = false;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        context.pop(code);
      }
    });
  }

  void _processBluetoothBarcode(String barcode) {
    if (_isProcessingBluetoothInput || _isReturning) return;

    _isProcessingBluetoothInput = true;
    _returnCode(barcode);
  }

  void _handleBluetoothInput(String value) {
    if (!isScanning || _isProcessingBluetoothInput || _isReturning) return;

    _bluetoothTimer?.cancel();
    if (value.isNotEmpty && value != _bluetoothBuffer) {
      _bluetoothBuffer = value;

      _bluetoothTimer = Timer(const Duration(milliseconds: 150), () {
        if (_bluetoothBuffer.isNotEmpty &&
            isScanning &&
            !_isProcessingBluetoothInput &&
            !_isReturning) {
          _processBluetoothBarcode(_bluetoothBuffer);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: context.loc.scanQRCode.titleBoldText(color: Colors.black),
      ),
      body: Stack(
        children: [
          // Camera Scanner
          MobileScanner(
            controller: controller,
            overlayBuilder: (context, constraints) {
              return QRScannerOverlay(
                overlayColour: Colors.black12,
                takeImage: widget.showGalleryButton ? takeFromGallery : null,
                focusColor: AppColor.primary,
                showGalleryButton: widget.showGalleryButton,
              );
            },
            errorBuilder: (p0, p1) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    10.ph,
                    context.loc.permissionDeniedTitle.bodyWithBoldText(),
                    20.ph,
                    CustomAppButton(
                      title: context.loc.openSettings,
                      onTap: () => openAppSettings(),
                    ),
                    200.ph,
                  ],
                ),
              );
            },
            onDetect: (result) {
              if (!isScanning || _isReturning) return;
              setState(() {
                isScanning = false;
              });
              EasyDebounce.debounce(
                'qr',
                const Duration(milliseconds: 500),
                () {
                  final loader = context.loaderOverlay;
                  loader.show();
                  final barcode = result.barcodes.first;
                  final String? code = barcode.rawValue;
                  if (code != null) {
                    loader.hide();
                    _returnCode(code);
                  } else {
                    CustomDialog.showAppToast(
                      "${context.loc.invalidQrCode}: $code",
                    );
                    setState(() {
                      isScanning = true;
                    });
                  }
                },
              );
            },
          ),

          // Bluetooth Scanner
          Positioned(
            left: -100,
            top: 0,
            child: SizedBox(
              width: 1,
              height: 1,
              child: TextField(
                focusNode: _bluetoothFocusNode,
                controller: barcodeScannerController,
                autofocus: true,
                onChanged: _handleBluetoothInput,
                inputFormatters: [
                  FilteringTextInputFormatter.singleLineFormatter,
                ],
                style: const TextStyle(fontSize: 1, height: 1),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '',
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QRScannerOverlay extends StatelessWidget {
  const QRScannerOverlay({
    super.key,
    required this.overlayColour,
    this.takeImage,
    this.focusColor,
    this.showGalleryButton = true,
  });

  final Color overlayColour;
  final Color? focusColor;
  final VoidCallback? takeImage;
  final bool showGalleryButton;

  @override
  Widget build(BuildContext context) {
    double scanArea =
        (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 220.0
        : 300.0;
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(overlayColour, BlendMode.srcOut),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.only(bottom: 50),
                child: Container(
                  height: scanArea,
                  width: scanArea,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.only(bottom: 50),
          child: CustomPaint(
            foregroundPainter: BorderPainter(focusColor),
            child: SizedBox(width: scanArea + 20, height: scanArea + 20),
          ),
        ),
        Container(
          alignment: Alignment.center,
          child: Column(
            children: [
              const Spacer(flex: 1),
              const SizedBox(height: 80),
              const Spacer(flex: 3),
              if (showGalleryButton && takeImage != null)
                Container(
                  margin: const EdgeInsets.only(
                    bottom: kBottomNavigationBarHeight,
                    left: 20,
                    right: 20,
                  ),
                  width: double.maxFinite,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: focusColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: takeImage,
                    child: context.loc.scanFromGallery.bodyWithBoldText(
                      color: Colors.white,
                    ),
                  ),
                ),
              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }
}

class BorderPainter extends CustomPainter {
  BorderPainter(this.borderColor);
  final Color? borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    const width = 4.0;
    const radius = 12.0;
    const tRadius = 3 * radius;
    final rect = Rect.fromLTWH(
      width,
      width,
      size.width - 2 * width,
      size.height - 2 * width,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(radius));
    const clippingRect0 = Rect.fromLTWH(0, 0, tRadius, tRadius);
    final clippingRect1 = Rect.fromLTWH(
      size.width - tRadius,
      0,
      tRadius,
      tRadius,
    );
    final clippingRect2 = Rect.fromLTWH(
      0,
      size.height - tRadius,
      tRadius,
      tRadius,
    );
    final clippingRect3 = Rect.fromLTWH(
      size.width - tRadius,
      size.height - tRadius,
      tRadius,
      tRadius,
    );

    final path = Path()
      ..addRect(clippingRect0)
      ..addRect(clippingRect1)
      ..addRect(clippingRect2)
      ..addRect(clippingRect3);

    canvas.clipPath(path);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = borderColor ?? Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
