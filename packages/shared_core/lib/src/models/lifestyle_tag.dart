/// Lifestyle preference tags for semester accommodation applications.
enum LifestyleTag {
  lateSleeper,
  earlyBird,
  airconUser,
  noAircon,
  quietPerson,
  social,
  smoker,
  nonSmoker,
  neatFreak,
  relaxed;

  /// Snake_case value stored in DB.
  String get dbValue => switch (this) {
        LifestyleTag.lateSleeper => 'late_sleeper',
        LifestyleTag.earlyBird => 'early_bird',
        LifestyleTag.airconUser => 'aircon_user',
        LifestyleTag.noAircon => 'no_aircon',
        LifestyleTag.quietPerson => 'quiet_person',
        LifestyleTag.social => 'social',
        LifestyleTag.smoker => 'smoker',
        LifestyleTag.nonSmoker => 'non_smoker',
        LifestyleTag.neatFreak => 'neat_freak',
        LifestyleTag.relaxed => 'relaxed',
      };

  /// Parse from DB snake_case string. Returns null if invalid.
  static LifestyleTag? fromDbValue(String value) {
    for (final tag in values) {
      if (tag.dbValue == value) return tag;
    }
    return null;
  }
}
