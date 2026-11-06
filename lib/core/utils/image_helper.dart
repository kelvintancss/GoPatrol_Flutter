import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/core/utils/app_extension.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageHelper {
  final ImagePicker _imagePicker;

  ImageHelper(this._imagePicker);

  static const double maxWidth = 1800;
  static const double maxHeight = 1800;
  static const String cameraAccessDeniedCode = "camera_access_denied";

  Future<XFile?> pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    return image;
  }

  Future<XFile?> takeCamera() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    return image;
  }

  Future<List<XFile>> pickMultipleImage({int max = 4}) async {
    final List<XFile> image = await _imagePicker.pickMultiImage(
      limit: max,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    return image;
  }

  Future<void> showSelectOptionImageResource(
    context, {
    required ValueNotifier<XFile?> myImg,
    required ValueNotifier<File?> imgFile,
    bool showFile = false,
    bool uploadMultiple = false,
  }) async {
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: context.loc.chooseAnOption.titleBoldText(),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              onPressed: () async {
                var loc = context.loc;
                final nav = Navigator.of(context);
                await Permission.camera.status;

                try {
                  await Permission.camera.request();
                  final XFile? photo = await takeCamera();
                  if (photo != null) {
                    myImg.value = photo;
                    imgFile.value = File(photo.path);
                  }
                } on PlatformException catch (p) {
                  if (p.code == cameraAccessDeniedCode) {
                    Fluttertoast.showToast(msg: loc.permissionDeniedTitle);
                    nav.pop();
                  }
                } catch (e) {
                  nav.pop();
                }
              },
              child: context.loc.openCamera.titleWithoutBoldText(),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                var loc = context.loc;
                final nav = Navigator.of(context);
                try {
                  if (uploadMultiple) {
                    final List<XFile> photos = await pickMultipleImage();
                    if (photos.isNotEmpty) {}
                  }
                  final XFile? photo = await pickImage();
                  if (photo != null) {
                    File local = File(photo.path);
                    final String targetPath =
                        '${local.parent.path}/compressed_${local.uri.pathSegments.last}';
                    final XFile? normalizedXFile = await normalizeImage(
                      photo.path,
                      targetPath,
                    );
                    myImg.value = normalizedXFile;
                    imgFile.value = File(normalizedXFile!.path);
                    nav.pop();
                  }
                } catch (e) {
                  Fluttertoast.showToast(msg: loc.uploadImageErrorMsg);
                  nav.pop();
                }
              },
              child: context.loc.selectFromGallery.titleWithoutBoldText(),
            ),
            if (showFile)
              CupertinoActionSheetAction(
                onPressed: () async {
                  final goRouter = GoRouter.of(context);
                  try {
                    final file = await uploadPdFile();
                    if (file.isNotEmpty) {
                      goRouter.pop(file.first);
                    }
                  } catch (_) {
                    goRouter.pop();
                  }
                },
                child: context.loc.uploadFiles.titleWithoutBoldText(),
              ),
            CupertinoActionSheetAction(
              onPressed: () => GoRouter.of(context).pop(),
              child: context.loc.cancelLabel.titleWithoutBoldText(),
            ),
          ],
        );
      },
    );
  }

  Future<File?> showSelectOptionImageResourceWithoutValueNotifier(
    context, {
    bool showFile = false,
  }) async {
    return showCupertinoModalPopup<File?>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: context.loc.chooseAnOption.titleBoldText(),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              onPressed: () async {
                var loc = context.loc;
                final goRouter = GoRouter.of(context);
                await Permission.camera.status;

                try {
                  await Permission.camera.request();
                  final XFile? photo = await takeCamera();
                  if (photo != null) {
                    goRouter.pop(File(photo.path));
                  }
                } on PlatformException catch (p) {
                  if (p.code == cameraAccessDeniedCode) {
                    Fluttertoast.showToast(msg: loc.permissionDeniedTitle);
                    goRouter.pop();
                  }
                } catch (e) {
                  goRouter.pop();
                }
              },
              child: context.loc.openCamera.titleWithoutBoldText(),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                final goRouter = GoRouter.of(context);
                try {
                  final XFile? photo = await pickImage();
                  if (photo != null) {
                    goRouter.pop(File(photo.path));
                  }
                } catch (_) {
                  goRouter.pop();
                }
              },
              child: context.loc.selectFromGallery.titleWithoutBoldText(),
            ),
            if (showFile)
              CupertinoActionSheetAction(
                onPressed: () async {
                  final goRouter = GoRouter.of(context);
                  try {
                    final file = await uploadPdFile();
                    if (file.isNotEmpty) {
                      goRouter.pop(file.first);
                    }
                  } catch (_) {
                    goRouter.pop();
                  }
                },
                child: context.loc.uploadFiles.titleWithoutBoldText(),
              ),
            CupertinoActionSheetAction(
              onPressed: () => GoRouter.of(context).pop(),
              child: context.loc.cancelLabel.titleWithoutBoldText(),
            ),
          ],
        );
      },
    );
  }

  Future<dynamic>? showSelectOptionImageListResourceWithoutValueNotifier(
    context, {
    bool showFile = false,
  }) async {
    return showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: context.loc.chooseAnOption.titleBoldText(),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              onPressed: () async {
                var loc = context.loc;
                final goRouter = GoRouter.of(context);
                await Permission.camera.status;
                try {
                  await Permission.camera.request();
                  final XFile? photo = await takeCamera();
                  if (photo != null) {
                    goRouter.pop([File(photo.path)]);
                  }
                } on PlatformException catch (p) {
                  if (p.code == cameraAccessDeniedCode) {
                    Fluttertoast.showToast(msg: loc.permissionDeniedTitle);
                    goRouter.pop();
                  }
                } catch (e) {
                  goRouter.pop();
                }
              },
              child: context.loc.openCamera.titleWithoutBoldText(),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                final goRouter = GoRouter.of(context);
                try {
                  final List<XFile> photos = await pickMultipleImage();
                  final normalize = await compressImages(photos);
                  if (normalize.isNotEmpty) {
                    goRouter.pop(normalize);
                  }
                } catch (_) {
                  goRouter.pop();
                }
              },
              child: context.loc.selectFromGallery.titleWithoutBoldText(),
            ),
            if (showFile)
              CupertinoActionSheetAction(
                onPressed: () async {
                  final goRouter = GoRouter.of(context);
                  try {
                    final file = await uploadPdFile();
                    if (file.isNotEmpty) {
                      goRouter.pop(file);
                    }
                  } catch (_) {
                    goRouter.pop();
                  }
                },
                child: context.loc.uploadFiles.titleWithoutBoldText(),
              ),
            CupertinoActionSheetAction(
              onPressed: () => GoRouter.of(context).pop(),
              child: context.loc.cancelLabel.titleWithoutBoldText(),
            ),
          ],
        );
      },
    );
  }

  Future<List<File>> uploadPdFile({bool isMultiple = false}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: isMultiple,
      );
      if (result != null) {
        List<File> files = result.paths.map((path) => File(path!)).toList();
        return files;
      }
    } catch (e) {
      debugPrint("upload file ${e.toString()}");
    }
    return [];
  }

  Future<double> calculateTotalSize(List<File> files) async {
    int totalBytes = 0;

    for (File file in files) {
      final bytes = await file.length(); // returns size in bytes
      totalBytes += bytes;
    }
    double totalMB = totalBytes / (1024 * 1024);
    return totalMB;
  }

  Future<XFile?> normalizeImage(String path, String targetPath) async {
    return await FlutterImageCompress.compressAndGetFile(
      path,
      targetPath,
      quality: 90,
      format: CompressFormat.jpeg,
    );
  }

  Future<List<File>> compressImages(List<XFile> photos) async {
    List<File> compressed = [];

    final tempDir = await getTemporaryDirectory();

    for (XFile photo in photos) {
      final targetPath =
          "${tempDir.path}compressed_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final result = await FlutterImageCompress.compressAndGetFile(
        photo.path,
        targetPath,
        quality: 70, // adjust this to control compression level
        minWidth: 800, // optional: normalize width
        minHeight: 800, // optional: normalize height
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        compressed.add(File(result.path));
      }
    }

    return compressed;
  }
}
