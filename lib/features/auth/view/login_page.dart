import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/app/app_router.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/services/user_preference.dart';
import 'package:patrol/core/utils/app_extension.dart';
import 'package:patrol/core/widgets/app_button_rounded.dart';
import 'package:patrol/core/widgets/app_text_field.dart';
import 'package:patrol/core/widgets/custom_dialog.dart';
import 'package:patrol/features/auth/cubit/auth_cubit.dart';
import 'package:patrol/features/auth/cubit/auth_state.dart';
import 'package:patrol/gen/assets.gen.dart';
import 'package:patrol/service_locator.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends HookWidget {
  final String projectId;
  final String projectName;

  const LoginPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    final usernameNode = useFocusNode();
    final passwordNode = useFocusNode();
    final usernameController = useTextEditingController();
    final passwordController = useTextEditingController();
    final adminPasswordController = useTextEditingController();
    final isObscure = useState(true);
    final authCubit = context.read<AuthCubit>();
    final adminTapCount = useState(0);
    final lastTapTime = useState<DateTime?>(null);

    final selectedProjectId = useMemoized(() {
      if (projectId.isNotEmpty) {
        return projectId;
      } else {
        return sl<UserPreferences>().getUserProjectId ?? '';
      }
    }, [projectId]);

    final selectedProjectName = useMemoized(() {
      if (projectName.isNotEmpty) {
        return projectName;
      } else {
        return sl<UserPreferences>().getUserProjectName ?? '';
      }
    }, [projectName]);

    void showAdminDialog() {
      adminPasswordController.clear();

      CustomDialog.showDialogImageWithOption(
        context,
        title: context.loc.adminVerificationTitle,
        desc: context.loc.adminVerificationDscp,
        confirmText: context.loc.confirmLabel,
        cancelText: context.loc.cancelLabel,
        bodyWidget: Column(
          children: [
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Image.asset(
                Assets.images.appIcon.path,
                height: 80.h,
                width: 80.w,
              ),
            ),
            const SizedBox(height: 20),
            HookBuilder(
              builder: (context) {
                final isObscureLocal = useState(true);
                return AppTextField(
                  controller: adminPasswordController,
                  hintText: context.loc.passwords,
                  isObscure: isObscureLocal.value,
                  stripEmojis: true,
                  line: 1,
                  suffixIcon: GestureDetector(
                    onTap: () => isObscureLocal.value = !isObscureLocal.value,
                    child: Icon(
                      isObscureLocal.value
                          ? CupertinoIcons.eye_slash
                          : CupertinoIcons.eye,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        confirmCallback: () async {
          final password = adminPasswordController.text.trim();

          if (password.isEmpty) {
            CustomDialog.showAppDialog(context.loc.adminPasswordValidation);
            return false; // Keep dialog open
          }

          // Trigger verification
          await authCubit.postVerifyAdminPassword(password: password);

          // IMPORTANT: Do NOT close the dialog here.
          // Let the BlocListener decide when to close based on the result.
          return false;
        },
      );
    }

    void handleAdminButtonTap() {
      final now = DateTime.now();
      if (lastTapTime.value != null &&
          now.difference(lastTapTime.value!).inSeconds > 2) {
        adminTapCount.value = 0;
      }
      lastTapTime.value = now;
      adminTapCount.value++;
      if (adminTapCount.value >= 7) {
        adminTapCount.value = 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showAdminDialog();
        });
      } else if (adminTapCount.value > 0 && adminTapCount.value < 7) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          CustomDialog.showAppToast('${adminTapCount.value}/7');
        });
      }
    }

    void subHandleLogin(BuildContext context) {
      if (usernameController.text.trim().isEmpty) {
        CustomDialog.showAppDialog(context.loc.usernameEmpty);
        return;
      }
      if (passwordController.text.trim().isEmpty) {
        CustomDialog.showAppDialog(context.loc.passwordEmpty);
        return;
      }

      authCubit.postLogin(
        projectId: selectedProjectId,
        projectName: selectedProjectName,
        loginId: usernameController.text.trim(),
        password: passwordController.text.trim(),
      );
    }

    void closeAdminDialogAndKeyboard(BuildContext context) {
      // Close the admin dialog
      Navigator.of(context).popUntil((route) {
        return route.settings.name == null || route.isFirst;
      });

      // Dismiss keyboard
      FocusScope.of(context).unfocus();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            BlocListener<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state.status == AuthenticateStatus.success) {
                  closeAdminDialogAndKeyboard(context);
                  context.go(AppRouter.property);
                } else if (state.status == AuthenticateStatus.fail) {
                  closeAdminDialogAndKeyboard(context);
                  CustomDialog.showAppDialog(context.loc.adminVerifyFail);
                } else if (state.status == AuthenticateStatus.error) {
                  closeAdminDialogAndKeyboard(context);
                  CustomDialog.showAppDialog(context.loc.adminVerifyError);
                } else if (state.status == AuthenticateStatus.loginSuccess) {
                  context.go(AppRouter.home);
                } else if (state.status == AuthenticateStatus.loginError) {
                  CustomDialog.showAppDialog(context.loc.loginFailed);
                }
              },
              child: Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      100.ph,
                      Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: Image.asset(
                          Assets.images.appIcon.path,
                          height: 100.h,
                          width: 100.w,
                        ),
                      ),
                      10.ph,
                      Container(
                        alignment: Alignment.center,
                        child: Text(
                          'CSS Patrol',
                          style: GoogleFonts.poppins(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      50.ph,
                      Container(
                        alignment: Alignment.topLeft,
                        child: context.loc.welcomeLabel.titleBoldText(
                          fontSize: 24,
                          color: Colors.black,
                        ),
                      ),
                      5.ph,
                      Container(
                        alignment: Alignment.topLeft,
                        child: context.loc.loginAccount.titleWithoutBoldText(
                          fontSize: 18,
                          color: AppColor.textGrey,
                        ),
                      ),
                      35.ph,
                      // Username
                      AppTextField(
                        focusNode: usernameNode,
                        controller: usernameController,
                        hintText: context.loc.username,
                        stripEmojis: true,
                      ),
                      20.ph,
                      // Password
                      AppTextField(
                        focusNode: passwordNode,
                        controller: passwordController,
                        hintText: context.loc.passwords,
                        isObscure: isObscure.value,
                        stripEmojis: true,
                        line: 1,
                        suffixIcon: GestureDetector(
                          onTap: () => isObscure.value = !isObscure.value,
                          child: Icon(
                            isObscure.value
                                ? CupertinoIcons.eye_slash
                                : CupertinoIcons.eye,
                          ),
                        ),
                      ),
                      20.ph,
                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          final isLoading =
                              state.status == AuthenticateStatus.loading ||
                              state.status == AuthenticateStatus.loginLoading;
                          return AppButtonRounded(
                            onTap: isLoading
                                ? null
                                : () => subHandleLogin(context),
                            btnText: isLoading
                                ? context.loc.loggingIn
                                : context.loc.login,
                            btnWidth: 300.w,
                            btnColor: AppColor.primary,
                          );
                        },
                      ),
                      20.ph,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Small round admin button
                  GestureDetector(
                    onTap: handleAdminButtonTap,
                    child: Container(
                      width: 22.w,
                      height: 22.h,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Text
                  Expanded(
                    child: Text(
                      'Currently you are in $selectedProjectName',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColor.textGrey,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Empty container for balance (optional)
                  SizedBox(width: 32.w),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
