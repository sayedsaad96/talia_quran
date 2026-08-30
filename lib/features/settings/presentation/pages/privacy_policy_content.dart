class PrivacySection {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const PrivacySection({
    required this.title,
    required this.paragraphs,
    this.bullets = const [],
  });
}

abstract class PrivacyPolicyContent {
  static const String arEffectiveDate = 'تاريخ النفاذ: 1 يونيو 2026';
  static const String enEffectiveDate = 'Effective Date: June 1, 2026';

  static const String arIntroSubtitle =
      'مرحباً بك في تطبيق تالية. تم إعداد سياسة الخصوصية هذه لمساعدتك في فهم كيفية جمع المعلومات واستخدامها وحمايتها عند استخدام تطبيقنا، مع قسم خاص مخصص لخصوصية الأطفال.';
  static const String enIntroSubtitle =
      'Welcome to Talia. This Privacy Policy is designed to help you understand how we collect, use, and safeguard the information you provide to us when using our app, with a special section dedicated to children\'s privacy.';
  static const String arManualOptionAction =
      'افتح الحفظ لاستخدام التقييم الذاتي';
  static const String enManualOptionAction =
      'Open memorization to use manual self-grade';

  static List<PrivacySection> getArabicContent() {
    return const [
      PrivacySection(
        title: '١. مقدمة',
        paragraphs: [
          'تطبيق تالية هو تطبيق إسلامي مخصص لقراءة وحفظ القرآن الكريم والأذكار. بنيتنا الأساسية تقوم على توفير بيئة روحية نقية، آمنة، وخالية من المشتتات لك ولأطفالك. نحن نحترم خصوصيتك وملتزمون بحمايتها بكل السبل الممكنة.',
        ],
      ),
      PrivacySection(
        title: '٢. المعلومات التي نجمعها',
        paragraphs: [
          'أ. البيانات الشخصية:\nعند إنشاء حساب (عبر Supabase)، نقوم بجمع البريد الإلكتروني (يُستخدم حصرياً للتحقق واستعادة الحساب) والاسم والعمر اختيارياً (يُستخدم لتخصيص التجربة وإصدار شهادات الحفظ).',
          'ب. بيانات الاستخدام والتقدم:\nلكي يعمل التطبيق بشكل صحيح، يتم حفظ تقدمك في الحفظ، والسلاسل اليومية (Streaks)، والعلامات المرجعية، والآيات المكتملة. تُحفظ هذه البيانات أساساً محلياً على جهازك، وقد تستخدم بعض ميزات الحساب بيانات سحابية محدودة عند تفعيلها.',
          'ج. صلاحيات الجهاز المطلوبة:',
        ],
        bullets: [
          'الميكروفون: يطلب التطبيق الوصول للميكروفون حصرياً لميزة "دقة التسميع" لتقييم قراءتك. يتم التعرف على الكلام عبر خدمة التعرف الصوتي المدمجة في نظام تشغيل جهازك، وقد تتم معالجة الصوت من قِبل مزوّد نظام التشغيل وفق سياساته الخاصة. لا يحتفظ تطبيق تالية بالصوت الخام ولا يرسله إلى خوادمنا، وإذا تعذّر استخدام الميكروفون يتوفر خيار التقييم الذاتي اليدوي داخل جلسة الحفظ.',
          'الإشعارات: تُستخدم لإرسال تنبيهات المراجعة اليومية، والأذكار، وورد القراءة محلياً على جهازك.',
          'معرض الصور/التخزين: يُطلب فقط عندما تختار حفظ شهادة إنجاز على جهازك.',
          'الكاميرا: تُستخدم حصرياً لمسح رمز QR لربط حساب ولي الأمر. لا يتم التقاط أو تخزين أي صور.',
        ],
      ),
      PrivacySection(
        title: '٣. خصوصية الأطفال وإقرار حماية بياناتهم (COPPA)',
        paragraphs: [
          'يحتوي تطبيق تالية على "مسار الأطفال" المخصص. ونحن ملتزمون تماماً بحماية خصوصية الأطفال والامتثال لقانون حماية خصوصية الأطفال على الإنترنت (COPPA) والأنظمة العالمية المماثلة.',
          'سياساتنا الصارمة تجاه مسار الأطفال تشمل:',
        ],
        bullets: [
          'عدم التنقيب عن البيانات: نحن لا نجمع أي بيانات شخصية حساسة من الأطفال إطلاقاً.',
          'إشراف ولي الأمر: تم تصميم ملف الطفل ليكون تحت إشراف كامل من ولي الأمر من خلال نظام ربط محلي آمن ومباشر (QR Code).',
          'خالٍ من الإعلانات والتتبع: لا يحتوي التطبيق على أي إعلانات موجهة لطرف ثالث، أو أدوات تتبع، أو إضافات لوسائل التواصل الاجتماعي تقوم بجمع بيانات الأطفال.',
          'المعالجة المحلية: عند استخدام الطفل للميكروفون للتسميع، يتم التعرف على الكلام عبر خدمة نظام التشغيل المدمجة وقد يعالجها مزوّد النظام وفق شروطه. لا يحتفظ تطبيق تالية بالصوت الخام ولا يرسله إلى خوادمنا، مع توفر بديل التقييم الذاتي اليدوي بإشراف ولي الأمر.',
        ],
      ),
      PrivacySection(
        title: '٤. كيف نحمي بياناتك',
        paragraphs: [
          'نحن نطبق مجموعة متنوعة من التدابير الأمنية الصارمة، بما في ذلك حماية مستوى الصفوف (Row Level Security - RLS) في خوادمنا السحابية لضمان أمان معلوماتك، بحيث لا يمكن لأي مستخدم الوصول إلا لبياناته الخاصة فقط.',
        ],
      ),
      PrivacySection(
        title: '٥. خدمات الطرف الثالث',
        paragraphs: [
          'نحن لا نبيع أو نتاجر ببياناتك أو ننقلها لأي أطراف خارجية. يستخدم التطبيق مزود الخدمة السحابية Supabase لتخزين الحسابات والميزات السحابية المحدودة عند تفعيلها.',
        ],
      ),
      PrivacySection(
        title: '٦. حقوقك القانونية',
        paragraphs: ['لديك الحق الكامل في:'],
        bullets: [
          'الوصول إلى بياناتك وتفاصيل تقدمك في أي وقت عبر التطبيق.',
          'تعديل ملفك الشخصي (الاسم، العمر).',
          'حذف حسابك السحابي من داخل التطبيق بعد تفعيل وظيفة Supabase المخصصة لذلك، أو طلب الحذف عبر التواصل معنا. يحذف ذلك حساب Supabase والبيانات السحابية المرتبطة به، ولا يحذف تقدمك المحلي المخزن على جهازك إلا إذا حذفت بيانات التطبيق من الجهاز.',
        ],
      ),
      PrivacySection(
        title: '٧. تواصل معنا',
        paragraphs: [
          'إذا كانت لديك أي استفسارات بخصوص سياسة الخصوصية هذه، يمكنك التواصل معنا عبر البريد الإلكتروني:',
          'elsayed.saad2014@feps.edu.eg',
        ],
      ),
    ];
  }

  static List<PrivacySection> getEnglishContent() {
    return const [
      PrivacySection(
        title: '1. Introduction',
        paragraphs: [
          'Talia is an Islamic application dedicated to Quran reading, memorization (Hifz), and Azkar. Our core philosophy is to provide a pure, distraction-free, and secure spiritual environment. We respect your privacy and are committed to protecting it.',
        ],
      ),
      PrivacySection(
        title: '2. Information We Collect',
        paragraphs: [
          'A. Personal Data:\nWhen you create an account (Supabase), we collect your Email Address (solely for authentication and account recovery) and optionally Display Name & Age (used to personalize the experience and generate certificates).',
          'B. Usage Data & Progress:\nTo function correctly, the app saves your memorization progress, daily streaks, bookmarks, and completed ayahs. This data is stored primarily on your device, and limited account features may use cloud data when enabled.',
          'C. Device Permissions:',
        ],
        bullets: [
          'Microphone: The app requests microphone access strictly for the Recitation Accuracy feature (evaluating your recitation). Speech recognition is performed by your device operating system\'s built-in speech service, and the platform provider may process audio under its own terms. Talia does not retain raw audio and does not send it to Talia servers; if the microphone is unavailable, a clearly labelled manual self-grade option is available inside the memorization session.',
          'Notifications: Used for daily reviews, Azkar, and reading reminders locally on your device.',
          'Storage/Gallery: Requested only when you choose to save an achievement certificate to your device.',
          'Camera: Used strictly for scanning a local QR code to link a Guardian (Parent) account. No images are captured or stored.',
        ],
      ),
      PrivacySection(
        title: '3. Children’s Privacy & COPPA Compliance',
        paragraphs: [
          'Talia includes a dedicated "Kids Track". We are fully committed to protecting the privacy of children and complying with the Children\'s Online Privacy Protection Act (COPPA) and similar global regulations.',
          'Our strict policies regarding children:',
        ],
        bullets: [
          'No Data Mining: We do not collect sensitive personal information (PII) from children.',
          'Guardian Link: The kids\' profile is designed to be monitored by a parent/guardian using a secure, local QR-code pairing system.',
          'No Tracking or Ads: The app does not contain third-party behavioral advertising, trackers, or social media plugins that profile children.',
          'Speech Recognition: When a child uses the microphone for recitation, speech recognition runs through the device operating system\'s built-in speech service and may be processed by the platform provider under its terms. Talia does not retain raw audio or send it to Talia servers; a guardian-supervised manual self-grade option is also available.',
        ],
      ),
      PrivacySection(
        title: '4. How We Protect Your Data',
        paragraphs: [
          'We implement a variety of security measures, including Row Level Security (RLS) on our cloud databases, to maintain the safety of your personal information. Only authenticated users can access their own specific data.',
        ],
      ),
      PrivacySection(
        title: '5. Third-Party Services',
        paragraphs: [
          'We do not sell, trade, or otherwise transfer your personally identifiable information to outside parties. The app uses Supabase as a secure backend-as-a-service provider for user accounts and limited cloud-enabled features.',
        ],
      ),
      PrivacySection(
        title: '6. Your Rights',
        paragraphs: ['You have the right to:'],
        bullets: [
          'Access your data anytime through the app.',
          'Edit your profile (Name, Age).',
          'Delete your cloud account in the app after the required Supabase function is deployed, or request deletion by contacting us. This removes your Supabase account and associated cloud data, but local progress stored on your device remains unless you delete the app data from the device.',
        ],
      ),
      PrivacySection(
        title: '7. Contact Us',
        paragraphs: [
          'If there are any questions regarding this privacy policy, you may contact us at:',
          'Email: elsayed.saad2014@feps.edu.eg',
        ],
      ),
    ];
  }
}
