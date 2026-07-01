// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_occupancy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RoomOccupancy _$RoomOccupancyFromJson(Map<String, dynamic> json) {
  return _RoomOccupancy.fromJson(json);
}

/// @nodoc
mixin _$RoomOccupancy {
  String get roomId => throw _privateConstructorUsedError;
  String get roomNumber => throw _privateConstructorUsedError;
  String get roomType =>
      throw _privateConstructorUsedError; // 'single' | 'twin_sharing'
  int get total => throw _privateConstructorUsedError;
  int get occupied => throw _privateConstructorUsedError;

  /// Serializes this RoomOccupancy to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RoomOccupancy
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RoomOccupancyCopyWith<RoomOccupancy> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoomOccupancyCopyWith<$Res> {
  factory $RoomOccupancyCopyWith(
          RoomOccupancy value, $Res Function(RoomOccupancy) then) =
      _$RoomOccupancyCopyWithImpl<$Res, RoomOccupancy>;
  @useResult
  $Res call(
      {String roomId,
      String roomNumber,
      String roomType,
      int total,
      int occupied});
}

/// @nodoc
class _$RoomOccupancyCopyWithImpl<$Res, $Val extends RoomOccupancy>
    implements $RoomOccupancyCopyWith<$Res> {
  _$RoomOccupancyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RoomOccupancy
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? roomId = null,
    Object? roomNumber = null,
    Object? roomType = null,
    Object? total = null,
    Object? occupied = null,
  }) {
    return _then(_value.copyWith(
      roomId: null == roomId
          ? _value.roomId
          : roomId // ignore: cast_nullable_to_non_nullable
              as String,
      roomNumber: null == roomNumber
          ? _value.roomNumber
          : roomNumber // ignore: cast_nullable_to_non_nullable
              as String,
      roomType: null == roomType
          ? _value.roomType
          : roomType // ignore: cast_nullable_to_non_nullable
              as String,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      occupied: null == occupied
          ? _value.occupied
          : occupied // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RoomOccupancyImplCopyWith<$Res>
    implements $RoomOccupancyCopyWith<$Res> {
  factory _$$RoomOccupancyImplCopyWith(
          _$RoomOccupancyImpl value, $Res Function(_$RoomOccupancyImpl) then) =
      __$$RoomOccupancyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String roomId,
      String roomNumber,
      String roomType,
      int total,
      int occupied});
}

/// @nodoc
class __$$RoomOccupancyImplCopyWithImpl<$Res>
    extends _$RoomOccupancyCopyWithImpl<$Res, _$RoomOccupancyImpl>
    implements _$$RoomOccupancyImplCopyWith<$Res> {
  __$$RoomOccupancyImplCopyWithImpl(
      _$RoomOccupancyImpl _value, $Res Function(_$RoomOccupancyImpl) _then)
      : super(_value, _then);

  /// Create a copy of RoomOccupancy
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? roomId = null,
    Object? roomNumber = null,
    Object? roomType = null,
    Object? total = null,
    Object? occupied = null,
  }) {
    return _then(_$RoomOccupancyImpl(
      roomId: null == roomId
          ? _value.roomId
          : roomId // ignore: cast_nullable_to_non_nullable
              as String,
      roomNumber: null == roomNumber
          ? _value.roomNumber
          : roomNumber // ignore: cast_nullable_to_non_nullable
              as String,
      roomType: null == roomType
          ? _value.roomType
          : roomType // ignore: cast_nullable_to_non_nullable
              as String,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      occupied: null == occupied
          ? _value.occupied
          : occupied // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RoomOccupancyImpl implements _RoomOccupancy {
  const _$RoomOccupancyImpl(
      {required this.roomId,
      required this.roomNumber,
      required this.roomType,
      required this.total,
      required this.occupied});

  factory _$RoomOccupancyImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoomOccupancyImplFromJson(json);

  @override
  final String roomId;
  @override
  final String roomNumber;
  @override
  final String roomType;
// 'single' | 'twin_sharing'
  @override
  final int total;
  @override
  final int occupied;

  @override
  String toString() {
    return 'RoomOccupancy(roomId: $roomId, roomNumber: $roomNumber, roomType: $roomType, total: $total, occupied: $occupied)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoomOccupancyImpl &&
            (identical(other.roomId, roomId) || other.roomId == roomId) &&
            (identical(other.roomNumber, roomNumber) ||
                other.roomNumber == roomNumber) &&
            (identical(other.roomType, roomType) ||
                other.roomType == roomType) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.occupied, occupied) ||
                other.occupied == occupied));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, roomId, roomNumber, roomType, total, occupied);

  /// Create a copy of RoomOccupancy
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RoomOccupancyImplCopyWith<_$RoomOccupancyImpl> get copyWith =>
      __$$RoomOccupancyImplCopyWithImpl<_$RoomOccupancyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RoomOccupancyImplToJson(
      this,
    );
  }
}

abstract class _RoomOccupancy implements RoomOccupancy {
  const factory _RoomOccupancy(
      {required final String roomId,
      required final String roomNumber,
      required final String roomType,
      required final int total,
      required final int occupied}) = _$RoomOccupancyImpl;

  factory _RoomOccupancy.fromJson(Map<String, dynamic> json) =
      _$RoomOccupancyImpl.fromJson;

  @override
  String get roomId;
  @override
  String get roomNumber;
  @override
  String get roomType; // 'single' | 'twin_sharing'
  @override
  int get total;
  @override
  int get occupied;

  /// Create a copy of RoomOccupancy
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RoomOccupancyImplCopyWith<_$RoomOccupancyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
