class OcrFrameItem {
  final int left1;
  final int left2;
  final int top1;
  final int top2;
  final int right1;
  final int right2;
  final int bottom1;
  final int bottom2;

  const OcrFrameItem({
    required this.left1,
    required this.left2,
    required this.top1,
    required this.top2,
    required this.right1,
    required this.right2,
    required this.bottom1,
    required this.bottom2,
  });

  Map<String, dynamic> toJson() => {
    'left1': left1,
    'left2': left2,
    'top1': top1,
    'top2': top2,
    'right1': right1,
    'right2': right2,
    'bottom1': bottom1,
    'bottom2': bottom2,
  };

  factory OcrFrameItem.fromJson(Map<String, dynamic> json) => OcrFrameItem(
    left1: json['left1'] as int,
    left2: json['left2'] as int,
    top1: json['top1'] as int,
    top2: json['top2'] as int,
    right1: json['right1'] as int,
    right2: json['right2'] as int,
    bottom1: json['bottom1'] as int,
    bottom2: json['bottom2'] as int,
  );

  OcrFrameItem copyWith({
    int? left1,
    int? left2,
    int? top1,
    int? top2,
    int? right1,
    int? right2,
    int? bottom1,
    int? bottom2,
  }) => OcrFrameItem(
    left1: left1 ?? this.left1,
    left2: left2 ?? this.left2,
    top1: top1 ?? this.top1,
    top2: top2 ?? this.top2,
    right1: right1 ?? this.right1,
    right2: right2 ?? this.right2,
    bottom1: bottom1 ?? this.bottom1,
    bottom2: bottom2 ?? this.bottom2,
  );

  @override
  String toString() =>
      'OcrFrameItem(left1: $left1, left2: $left2, top1: $top1, top2: $top2, right1: $right1, right2: $right2, bottom1: $bottom1, bottom2: $bottom2)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrFrameItem &&
          left1 == other.left1 &&
          left2 == other.left2 &&
          top1 == other.top1 &&
          top2 == other.top2 &&
          right1 == other.right1 &&
          right2 == other.right2 &&
          bottom1 == other.bottom1 &&
          bottom2 == other.bottom2;

  @override
  int get hashCode => Object.hash(left1, left2, top1, top2, right1, right2, bottom1, bottom2);
}