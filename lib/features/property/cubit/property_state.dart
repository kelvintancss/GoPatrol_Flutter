import 'package:equatable/equatable.dart';
import 'package:patrol/core/model/property_item.dart';

enum PropertyStatus { loading, init, error, success, getEntranceSuccess }

class PropertyState extends Equatable {
  final PropertyStatus status;
  final PropertyItem? propertyItem;
  final String projectCode;

  const PropertyState({
    this.status = PropertyStatus.init,
    this.propertyItem,
    this.projectCode = ''
  });

  PropertyState copyWith({
    PropertyStatus? status,
    PropertyItem? propertyItem,
    String? projectCode
  }) {
    return PropertyState(
      status: status ?? this.status,
      propertyItem: propertyItem ?? this.propertyItem,
      projectCode: projectCode ?? this.projectCode
    );
  }

  @override
  List<Object?> get props => [status, propertyItem, projectCode];
}
