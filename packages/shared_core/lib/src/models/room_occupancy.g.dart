// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_occupancy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RoomOccupancyImpl _$$RoomOccupancyImplFromJson(Map<String, dynamic> json) =>
    _$RoomOccupancyImpl(
      roomId: json['roomId'] as String,
      roomNumber: json['roomNumber'] as String,
      roomType: json['roomType'] as String,
      total: (json['total'] as num).toInt(),
      occupied: (json['occupied'] as num).toInt(),
    );

Map<String, dynamic> _$$RoomOccupancyImplToJson(_$RoomOccupancyImpl instance) =>
    <String, dynamic>{
      'roomId': instance.roomId,
      'roomNumber': instance.roomNumber,
      'roomType': instance.roomType,
      'total': instance.total,
      'occupied': instance.occupied,
    };
