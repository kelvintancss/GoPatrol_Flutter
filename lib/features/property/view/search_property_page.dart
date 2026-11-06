import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/app/app_router.dart';
import 'package:patrol/core/utils/app_extension.dart';
import 'package:patrol/core/widgets/custom_app_bar.dart';
import 'package:patrol/core/widgets/custom_dialog.dart';
import 'package:patrol/core/widgets/empty_item_widget.dart';
import 'package:patrol/features/property/cubit/property_cubit.dart';
import 'package:patrol/features/property/cubit/property_state.dart';
import 'package:patrol/features/property/widgets/search_bar_code.dart';
import 'package:patrol/features/property/widgets/property_list_tile.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:patrol/core/widgets/custom_scroll_widget.dart';
import 'package:patrol/core/widgets/custom_sliver_grid.dart';

class SearchPropertyPage extends StatefulWidget {
  final bool isOpenScan;

  const SearchPropertyPage({super.key, this.isOpenScan = false});

  @override
  State<SearchPropertyPage> createState() => _SearchPropertyPageState();
}

class _SearchPropertyPageState extends State<SearchPropertyPage> {
  final node = FocusNode();
  late final TextEditingController controller;
  bool customIcon = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    final cubit = context.read<PropertyCubit>();
    // Optionally, you can fetch a default list or clear state here if needed
    if (widget.isOpenScan) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final loader = context.loaderOverlay;
        final errorTxt = context.loc.invalidQrCode;
        node.unfocus();
        final result = await context.push(
          AppRouter.scanQr,
          extra: {'showGalleryButton': true},
        );
        loader.hide();

        node.unfocus();
        if (result != null) {
          try {
            var projectCode = result.toString().toUpperCase();
            if (!projectCode.startsWith('P-')) {
              var data = jsonDecode(result.toString());
              projectCode = data['project_code'];
            }
            //var data = jsonDecode(result.toString());
            await cubit.getPropertyId(projectCode: projectCode);
          } catch (e) {
            CustomDialog.showAppDialog(errorTxt);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    node.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        backgroundColor: Colors.transparent,
        titleSpacing: 0,
        title: Builder(
          builder: (context) {
            return SearchBarCode(
              focusNode: node,
              isAutoFocus: true,
              controller: controller,
              onSubmitted: (value) async {
                if (value.isNotEmpty) {
                  await context.read<PropertyCubit>().getPropertyId(
                    projectCode: value,
                  );
                }
              },
              onClickSearch: () async {
                await context.read<PropertyCubit>().getPropertyId(
                  projectCode: controller.text,
                );
              },
              scanCode: () async {
                final loader = context.loaderOverlay;
                final errorTxt = context.loc.invalidQrCode;
                final propertyCubit = context.read<PropertyCubit>();
                node.unfocus();
                final result = await context.push(
                  AppRouter.scanQr,
                  extra: {'showGalleryButton': true},
                );
                loader.hide();

                if (!mounted) return;

                node.unfocus();
                if (result != null) {
                  try {
                    var projectCode = result.toString().toUpperCase();
                    if (!projectCode.startsWith('P-')) {
                      var data = jsonDecode(result.toString());
                      projectCode = data['project_code'];
                    }
                    await propertyCubit.getPropertyId(
                      projectCode: projectCode,
                    );
                  } catch (e) {
                    CustomDialog.showAppDialog(errorTxt);
                  }
                }
              },
            );
          },
        ),
      ),
      body: BlocBuilder<PropertyCubit, PropertyState>(
        builder: (context, state) {
          if (state.status == PropertyStatus.loading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (state.status == PropertyStatus.error) {
            return Center(
              child: EmptyItemWidget(
                title: context.loc.noPropertyFound,
                imgPath: 'assets/images/my_property_emt-list-icon.png',
              ),
            );
          }

          if (state.status == PropertyStatus.success) {
            final property = state.propertyItem;
            final projectId = property?.projectData?.projectId ?? "-";
            final projectName = property?.projectData?.projectName ?? "-";

            return CustomScrollWidget(
              child: [
                CustomAppSliverGridView(
                  maxPerRow: 1,
                  children: [
                    PropertyListTile(
                      projectId: projectId,
                      projectName: projectName,
                      btmPadding: 5.0,
                    ),
                  ],
                ),
              ],
            );
          }

          return Center(
            child: EmptyItemWidget(
              title: context.loc.noPropertyFound,
              imgPath: 'assets/images/my_property_emt-list-icon.png',
            ),
          );
        },
      ),
    );
  }
}
