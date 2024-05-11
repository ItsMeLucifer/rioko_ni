part of 'region.dart';

class RegionAdapter extends TypeAdapter<Region> {
  @override
  final int typeId = 1;

  @override
  Region read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Region(
      polygons: (fields[0] as List)
          .map((e) => (e as List).map((e2) {
                final list = (e2 as List).cast<double>();
                return LatLng(list.first, list.last);
              }).toList())
          .toList(),
      code: fields[1] as String,
      name: fields[2] as String,
      type: fields[3] as String,
      countryCode: fields[4] as String,
      status: fields[6] as MOStatus,
    );
  }

  @override
  void write(BinaryWriter writer, Region obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.polygons
          .map((p) => p.map((p2) => [p2.latitude, p2.longitude]).toList())
          .toList())
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.countryCode)
      ..writeByte(5)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
