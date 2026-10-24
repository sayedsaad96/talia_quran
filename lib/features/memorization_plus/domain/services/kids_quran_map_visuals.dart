import 'kids_surah_house_summary_builder.dart';

/// The stars a surah house shows on the Quran journey map: a completed
/// surah always earns three; anything else keeps what its progress earned,
/// so a house awaiting review does not lose its stars.
int kidsSurahStars(KidsSurahHouse house) {
  if (house.status == KidsSurahHouseStatus.completed) return 3;
  return (house.progress * 3).floor().clamp(0, 3).toInt();
}

/// The cartoon islands the journey map cycles through, one per row.
enum KidsIsland {
  palmsLantern,
  domeHouse,
  waterfall,
  sandFort,
  camel,
  mushafStand,
  oasisTent,
  flowerGarden;

  /// The transparent 512 px island art for this island.
  String get asset => 'assets/images/kids/islands/island_${name}.png';
}

/// The island for row [index] of the journey map, keyed by row index and
/// not by surah id, because path order is not always sequential surah ids
/// and adjacent rows must never share an island.
KidsIsland kidsIslandForRow(int index) => KidsIsland.values[index % 8];
