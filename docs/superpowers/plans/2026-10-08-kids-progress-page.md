# Kids progress page ("تقدّمي" للأطفال) + guardian view

Date: 2026-10-08. Owner approved: a separate kids page, new kids-only
achievements, and the guardian can print and share each child's certificates.

Builds on the 2026-10-08 kids/adult split: adult home and "تقدمي" read only the
primary learner; the kids track has its own streak (`KidsStreakStore`),
kids-tagged activity (`isKids`), and its reading receipts.

## Scope

1. **Kids achievements (domain).** A pure catalog evaluates kids-only inputs
   (memorized ayahs, surah certificates, pages read, longest kids streak,
   stars) into milestones with progress. Unlocks are persisted per owner with
   their date, so a milestone never re-locks (reading receipts keep 60 days).
2. **Kids "تقدّمي" page** at `/memorization-plus/kids-progress`, opened from a
   button beside "كنوزي" on the kids home. Sections: summary (level, stars,
   kids streak, memorized ayahs), pages read this week, «إنجازاتي», «شهاداتي»
   (opens the existing certificate page: share / save / print), recent kids
   activity. Kids world style, no adult numbers.
3. **Guardian view.** In each child's page in the family dashboard, a
   "التقدم والإنجازات والشهادات" panel with the same numbers, achievements and
   certificates; each certificate opens the certificate page with the child's
   name, so the guardian can print and share it.
   - Same-device child: read locally.
   - Linked child on another device: progress from `kids_progress_cloud`,
     certificates from `certificate_awards_cloud` (surah/juz recovered from the
     id by `CertificateAward.fromCloudRow`), achievements and recent activity
     from the family activity snapshot. The snapshot gains an optional
     `achievements` array; the server accepts extra keys, so **no migration**.

## Decisions

| Decision | Choice | Why |
|---|---|---|
| Achievements re-lock when data ages out? | Never: unlocks persisted with date | Receipts keep 60 days; a child must not lose a badge |
| Pages read shown | Distinct pages in the last 7 days | Receipts are per day; a weekly number is honest and motivating |
| Memorized ayahs (kids) | `KidsProgress.ayahsCompleted` | Same number the kids home and guardian already use |
| Surah milestones | Count of kids surah certificates | Certificates are the existing, verified "surah memorized" signal |
| Achievements to guardian | Optional `achievements` key in the snapshot | Existing RPC validates only required keys; no schema change |
| Certificate names in guardian view | Child's display name | The certificate is the child's |
