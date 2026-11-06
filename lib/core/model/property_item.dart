import 'dart:convert';

PropertyItem projectIdFromJson(String str) =>
    PropertyItem.fromJson(json.decode(str));
String projectIdToJson(PropertyItem data) => json.encode(data.toJson());

class PropertyItem {
  final ProjectData? projectData;

  const PropertyItem({this.projectData});

  PropertyItem copyWith({ProjectData? projectData}) {
    return PropertyItem(projectData: projectData ?? this.projectData);
  }

  factory PropertyItem.fromJson(Map<String, dynamic> json) {
    return PropertyItem(
      projectData: json['project_data'] == null
          ? null
          : ProjectData.fromJson(json['project_data']),
    );
  }

  // object → JSON map
  Map<String, dynamic> toJson() => {'project_data': projectData?.toJson()};

  // Aliases — very common in Flutter repos / data layers
  factory PropertyItem.fromMap(Map<String, dynamic> map) =>
      PropertyItem.fromJson(map);
  Map<String, dynamic> toMap() => toJson();
}

class ProjectData {
  final String? projectId;
  final String? projectName;

  const ProjectData({this.projectId, this.projectName});

  ProjectData copyWith({String? projectId, String? projectName}) {
    return ProjectData(
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
    );
  }

  factory ProjectData.fromJson(Map<String, dynamic> json) {
    return ProjectData(
      projectId: json['project_id'] as String?,
      projectName: json['project_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'project_id': projectId,
    'project_name': projectName,
  };

  factory ProjectData.fromMap(Map<String, dynamic> map) =>
      ProjectData.fromJson(map);
  Map<String, dynamic> toMap() => toJson();
}
