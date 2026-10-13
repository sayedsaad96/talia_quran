import '../entities/kids_session_policy.dart';

/// Stable ids of the built-in, educational home-mission templates. The
/// guardian's chosen text is stored as the mission title, so these ids are
/// never persisted; they only pick which suggestion chips a guardian sees.
enum KidsHomeMissionTemplateId {
  tidyRoom,
  helpTable,
  kindWord,
  shareToy,
  tellLearning,
  prepareBag,
}

/// A suggestion the guardian may pick and edit before assigning. Templates
/// carry no religious attribution and no reward; assigning one goes through
/// the ordinary home-mission creation path.
class KidsHomeMissionTemplate {
  const KidsHomeMissionTemplate(this.id, this.ageBands);

  final KidsHomeMissionTemplateId id;
  final Set<KidsAgeBand> ageBands;
}

abstract final class KidsHomeMissionTemplates {
  static const _both = {KidsAgeBand.fiveToSeven, KidsAgeBand.eightToTwelve};

  static const all = <KidsHomeMissionTemplate>[
    KidsHomeMissionTemplate(KidsHomeMissionTemplateId.tidyRoom, _both),
    KidsHomeMissionTemplate(KidsHomeMissionTemplateId.helpTable, _both),
    KidsHomeMissionTemplate(KidsHomeMissionTemplateId.kindWord, _both),
    KidsHomeMissionTemplate(KidsHomeMissionTemplateId.shareToy, {
      KidsAgeBand.fiveToSeven,
    }),
    KidsHomeMissionTemplate(KidsHomeMissionTemplateId.tellLearning, _both),
    KidsHomeMissionTemplate(KidsHomeMissionTemplateId.prepareBag, {
      KidsAgeBand.eightToTwelve,
    }),
  ];

  /// The four suggestions every guardian saw before age-banded templates.
  static const legacy = <KidsHomeMissionTemplateId>[
    KidsHomeMissionTemplateId.tidyRoom,
    KidsHomeMissionTemplateId.helpTable,
    KidsHomeMissionTemplateId.kindWord,
    KidsHomeMissionTemplateId.shareToy,
  ];

  static List<KidsHomeMissionTemplateId> idsFor(KidsAgeBand ageBand) => [
    for (final template in all)
      if (template.ageBands.contains(ageBand)) template.id,
  ];
}
