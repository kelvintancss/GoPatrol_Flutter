class AppSettingModel {
  final ResultSet? resultSet;

  AppSettingModel({this.resultSet});

  AppSettingModel copyWith({ResultSet? resultSet}) => AppSettingModel(resultSet: resultSet ?? this.resultSet);

  factory AppSettingModel.fromJson(Map<String, dynamic> json) =>
      AppSettingModel(resultSet: json["resultSet"] == null ? null : ResultSet.fromJson(json["resultSet"]));

  Map<String, dynamic> toJson() => {"resultSet": resultSet?.toJson()};
}

class ResultSet {
  final App? app;

  ResultSet({this.app});

  ResultSet copyWith({App? app}) => ResultSet(app: app ?? this.app);

  factory ResultSet.fromJson(Map<String, dynamic> json) =>
      ResultSet(app: json["app"] == null ? null : App.fromJson(json["app"]));

  Map<String, dynamic> toJson() => {"app": app?.toJson()};
}

class App {
  final String? currentversion;
  final int? minversion;
  final bool? isForceUpdate;

  App({this.currentversion, this.minversion, this.isForceUpdate});

  App copyWith({String? currentversion, int? minversion, bool? isForceUpdate}) => App(
    currentversion: currentversion ?? this.currentversion,
    minversion: minversion ?? this.minversion,
    isForceUpdate: isForceUpdate ?? this.isForceUpdate,
  );

  factory App.fromJson(Map<String, dynamic> json) => App(
    currentversion: json["currentversion"],
    minversion: json["minversion"],
    isForceUpdate: json["is_force_update"],
  );

  Map<String, dynamic> toJson() => {
    "currentversion": currentversion,
    "minversion": minversion,
    "is_force_update": isForceUpdate,
  };
}
