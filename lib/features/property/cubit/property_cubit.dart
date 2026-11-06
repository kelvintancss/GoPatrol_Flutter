import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:patrol/core/repository/property_repository.dart';
import 'package:patrol/features/property/cubit/property_state.dart';
import 'package:patrol/service_locator.dart';

class PropertyCubit extends Cubit<PropertyState> {
  PropertyCubit() : super(const PropertyState());

  final PropertyRepository _propertyRepository = sl<PropertyRepository>();

  Future<void> getPropertyId({String projectCode = ''}) async {
    emit(state.copyWith(status: PropertyStatus.loading));
    try {
      final res = await _propertyRepository.getProjectId(
        projectCode: projectCode.trim(),
      );
      if (res != null) {
        emit(
          state.copyWith(
            propertyItem: res,
            status: PropertyStatus.success,
            projectCode: projectCode,
          ),
        );
      } else {
        emit(state.copyWith(status: PropertyStatus.error));
      }
    } catch (e) {
      debugPrint(e.toString());
      emit(state.copyWith(status: PropertyStatus.error));
    }
  }

  void resetProperty() => emit(const PropertyState());
}
