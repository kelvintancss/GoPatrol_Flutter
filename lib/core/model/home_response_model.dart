class HomeResponseModel {
  final ProjectInfo? projectInfo;
  final VisitorCarparkInfo? visitorCarparkInfo;
  final ActiveVisitorStats? activeVisitorStats;
  final MagBarrierSettingItem? magBarrierSettingItem;
  final GoGuardVersion? goguardVersion;

  HomeResponseModel({
    this.projectInfo,
    this.visitorCarparkInfo,
    this.activeVisitorStats,
    this.magBarrierSettingItem,
    this.goguardVersion,
  });

  factory HomeResponseModel.fromJson(Map<String, dynamic> json) =>
      HomeResponseModel(
        projectInfo: json["project_info"] == null
            ? null
            : ProjectInfo.fromJson(json["project_info"]),
        visitorCarparkInfo: json["visitor_carpark_info"] == null
            ? null
            : VisitorCarparkInfo.fromJson(json["visitor_carpark_info"]),
        activeVisitorStats: json["active_visitor_stats"] == null
            ? null
            : ActiveVisitorStats.fromJson(json["active_visitor_stats"]),
        magBarrierSettingItem: json["MAG_barrier_setting"] == null
            ? null
            : MagBarrierSettingItem.fromJson(json["MAG_barrier_setting"]),
        goguardVersion: json["goguard_version"] == null
            ? null
            : GoGuardVersion.fromJson(json["goguard_version"]),
      );

  Map<String, dynamic> toJson() => {
    "project_info": projectInfo?.toJson(),
    "visitor_carpark_info": visitorCarparkInfo?.toJson(),
    "active_visitor_stats": activeVisitorStats?.toJson(),
    "MAG_barrier_setting": magBarrierSettingItem?.toJson(),
  };
}

class ActiveVisitorStats {
  final int? activeVisitor;
  final int? expiredActiveVisitor;
  final int? totalActiveVisitors;

  ActiveVisitorStats({
    this.activeVisitor,
    this.expiredActiveVisitor,
    this.totalActiveVisitors,
  });

  factory ActiveVisitorStats.fromJson(Map<String, dynamic> json) =>
      ActiveVisitorStats(
        activeVisitor: json["active_visitor"],
        expiredActiveVisitor: json["expired_active_visitor"],
        totalActiveVisitors: json["total_active_visitors"],
      );

  Map<String, dynamic> toJson() => {
    "active_visitor": activeVisitor,
    "expired_active_visitor": expiredActiveVisitor,
    "total_active_visitors": totalActiveVisitors,
  };
}

class ProjectInfo {
  final String? projectName;
  final String? entrance;

  ProjectInfo({this.projectName, this.entrance});

  factory ProjectInfo.fromJson(Map<String, dynamic> json) => ProjectInfo(
    projectName: json["project_name"],
    entrance: json["entrance"],
  );

  Map<String, dynamic> toJson() => {
    "project_name": projectName,
    "entrance": entrance,
  };
}

class VisitorCarparkInfo {
  final int? availableParking;
  final int? usedParking;
  final int? disabledParking;
  final int? totalParkingSpaces;

  VisitorCarparkInfo({
    this.availableParking,
    this.usedParking,
    this.disabledParking,
    this.totalParkingSpaces,
  });

  factory VisitorCarparkInfo.fromJson(Map<String, dynamic> json) =>
      VisitorCarparkInfo(
        availableParking: json["available_parking"],
        usedParking: json["used_parking"],
        disabledParking: json["disabled_parking"],
        totalParkingSpaces: json["total_parking_spaces"],
      );

  Map<String, dynamic> toJson() => {
    "available_parking": availableParking,
    "used_parking": usedParking,
    "disabled_parking": disabledParking,
    "total_parking_spaces": totalParkingSpaces,
  };
}

class MagBarrierSettingItem {
  final bool? isEnabled;

  MagBarrierSettingItem({this.isEnabled});

  factory MagBarrierSettingItem.fromJson(Map<String, dynamic> json) =>
      MagBarrierSettingItem(isEnabled: json["is_enabled"]);

  Map<String, dynamic> toJson() => {"is_enabled": isEnabled};
}

class GoGuardVersion {
  final String? currentVersion;

  GoGuardVersion({this.currentVersion});

  factory GoGuardVersion.fromJson(Map<String, dynamic> json) =>
      GoGuardVersion(currentVersion: json["currentversion"]);

  Map<String, dynamic> toJson() => {"currentversion": currentVersion};
}
