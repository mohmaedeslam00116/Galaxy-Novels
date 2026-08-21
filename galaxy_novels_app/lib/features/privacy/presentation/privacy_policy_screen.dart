import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/navigation/external_uri_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({this.uriLauncher = launchExternalUri, super.key});

  final ExternalUriLauncher uriLauncher;

  static final _googlePartnersUri = Uri.parse(
    'https://policies.google.com/technologies/partner-sites?hl=ar',
  );
  static final _googleAdsSettingsUri = Uri.parse(
    'https://adssettings.google.com/',
  );
  static final _contactUri = Uri.parse('https://galaxynovels.com/contact/');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Scaffold(
      appBar: AppBar(title: const Text('سياسة الخصوصية')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _PolicyIntroduction(),
                    const SizedBox(height: 26),
                    const _PolicySection(
                      title: '1. المعلومات التي نجمعها',
                      children: [
                        _PolicySubheading('1.1 المعلومات التي تقدمها'),
                        _PolicyBullets([
                          'تفضيلات التطبيق التي تختارها مثل المظهر وحجم الخط.',
                          'الفصول التي تختار تنزيلها على جهازك.',
                        ]),
                        _PolicySubheading('1.2 المعلومات التي تُجمع تلقائياً'),
                        _PolicyBullets([
                          'معلومات الجهاز، مثل الطراز ونظام التشغيل.',
                          'معلومات الاستخدام، مثل الصفحات المقروءة والوقت المستغرق.',
                          'أحداث استخدام مجمّعة عبر Firebase Analytics، مثل فتح مخطط التنزيل وعدد الفصول وحالة نجاح العملية، دون إرسال أسماء الروايات أو الفصول أو معرّف الحساب.',
                          'بيانات الأداء التقني وتشخيص الأعطال.',
                        ]),
                      ],
                    ),
                    const _PolicySection(
                      title: '2. استخدام معلوماتك',
                      children: [
                        _PolicyBullets([
                          'تقديم وظائف التطبيق الأساسية.',
                          'تطوير وتحسين خدمات التطبيق وتجربة القراءة.',
                          'تخصيص تجربة القراءة بحسب اختياراتك.',
                          'تحليل استخدام التطبيق لتحسين الأداء.',
                          'حل المشكلات التقنية وتحسين الخدمات.',
                        ]),
                      ],
                    ),
                    _PolicySection(
                      title: '3. الإعلانات وجمع البيانات',
                      children: [
                        const _PolicyParagraph(
                          'يستخدم هذا التطبيق Google AdMob لعرض الإعلانات. قد تجمع Google وشركاؤها معلومات معينة لتحسين الإعلانات، بما في ذلك:',
                        ),
                        const _PolicyBullets([
                          'معرّفات الجهاز الإعلانية.',
                          'عنوان IP.',
                          'بيانات الموقع التقريبية.',
                          'معلومات الجهاز.',
                          'بيانات التفاعل مع الإعلان.',
                        ]),
                        const _PolicyParagraph(
                          'يستخدم التطبيق Firebase Analytics لقياس نجاح رحلة التنزيل وتحسينها. تقتصر الأحداث المخصصة على أعداد وحالات عامة ومستوى العضوية، ولا تتضمن نص الفصل أو اسم الرواية أو اسم المستخدم.',
                        ),
                        _PolicyLinkCard(
                          key: const ValueKey('privacy-google-data-link'),
                          label:
                              'كيفية استخدام Google للمعلومات من المواقع أو التطبيقات',
                          uri: _googlePartnersUri,
                          onOpen: _openUri,
                        ),
                      ],
                    ),
                    _PolicySection(
                      title: '4. خياراتك وحقوقك',
                      children: [
                        const _PolicySubheading('4.1 التحكم في الإعلانات'),
                        const _PolicyParagraph(
                          'يمكنك إدارة الإعلانات المخصصة من خلال إعدادات جهازك أو عبر إعدادات إعلانات Google.',
                        ),
                        _PolicyLinkCard(
                          key: const ValueKey('privacy-google-ads-link'),
                          label: 'إدارة تفضيلات إعلانات Google',
                          uri: _googleAdsSettingsUri,
                          onOpen: _openUri,
                        ),
                        const _PolicySubheading('4.2 حقوقك في البيانات'),
                        const _PolicyParagraph(
                          'يمكنك حذف البيانات المحلية من إعدادات جهازك، أو التواصل معنا لطلب الوصول إلى بياناتك أو حذفها.',
                        ),
                      ],
                    ),
                    const _PolicySection(
                      title: '5. تخزين البيانات',
                      children: [
                        _PolicyParagraph(
                          'تُخزن بيانات التطبيق المحلية بصورة آمنة على جهازك، ولا تُشارك مع جهات خارجية إلا عند الحاجة لتقديم الخدمات الموضحة في هذه السياسة.',
                        ),
                      ],
                    ),
                    const _PolicySection(
                      title: '6. الأطفال',
                      children: [
                        _PolicyParagraph(
                          'تطبيقنا غير موجه للأطفال دون سن 13 عاماً. نحن لا نجمع عن قصد معلومات شخصية من الأطفال، وإذا كنت ولي أمر وعلمت أن طفلك قدم لنا معلومات، يرجى التواصل معنا.',
                        ),
                      ],
                    ),
                    const _PolicySection(
                      title: '7. الأمان',
                      children: [
                        _PolicyParagraph(
                          'نتخذ تدابير معقولة لحماية المعلومات من الوصول غير المصرح به، ويتم الاتصال بالخدمات عبر اتصالات HTTPS مشفرة كلما كان ذلك متاحاً.',
                        ),
                      ],
                    ),
                    const _PolicySection(
                      title: '8. التغييرات على سياسة الخصوصية',
                      children: [
                        _PolicyParagraph(
                          'قد نقوم بتحديث سياسة الخصوصية من وقت لآخر. سنخطرك بأي تغييرات مهمة من خلال التطبيق أو بنشر النسخة المحدثة وتاريخ سريانها.',
                        ),
                      ],
                    ),
                    _PolicySection(
                      title: '9. اتصل بنا',
                      children: [
                        const _PolicyParagraph(
                          'إذا كانت لديك أي أسئلة حول سياسة الخصوصية، يمكنك التواصل معنا من خلال صفحة الاتصال الرسمية.',
                        ),
                        _PolicyLinkCard(
                          key: const ValueKey('privacy-contact-link'),
                          label: 'التواصل مع مجرة الروايات',
                          uri: _contactUri,
                          onOpen: _openUri,
                        ),
                      ],
                    ),
                    const _PolicySection(
                      title: '10. الامتثال للقوانين',
                      children: [
                        _PolicyParagraph('تتوافق هذه السياسة مع مبادئ:'),
                        _PolicyBullets([
                          'اللائحة العامة لحماية البيانات للاتحاد الأوروبي (GDPR).',
                          'قانون خصوصية المستهلك في كاليفورنيا (CCPA).',
                          'قانون حماية خصوصية الأطفال على الإنترنت (COPPA).',
                        ]),
                      ],
                    ),
                    _AcceptanceCard(tokens: tokens),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUri(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await uriLauncher(uri);
    } on Exception {
      opened = false;
    }
    if (!opened && messenger.mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('تعذر فتح الرابط الآن.')),
      );
    }
  }
}

class _PolicyIntroduction extends StatelessWidget {
  const _PolicyIntroduction();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(Icons.privacy_tip_rounded, color: tokens.accent, size: 36),
            const SizedBox(height: 12),
            Text(
              'سياسة الخصوصية لتطبيق مجرة الروايات',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w900,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'آخر تحديث: 8 أغسطس 2026',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'نحن نحترم خصوصيتك ونلتزم بحماية بياناتك الشخصية. توضح هذه السياسة كيفية جمع واستخدام وحماية المعلومات عند استخدام التطبيق.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: tokens.accent,
              fontWeight: FontWeight.w900,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _PolicySubheading extends StatelessWidget {
  const _PolicySubheading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
          height: 1.5,
        ),
      ),
    );
  }
}

class _PolicyParagraph extends StatelessWidget {
  const _PolicyParagraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: tokens.textSecondary,
          height: 1.75,
        ),
      ),
    );
  }
}

class _PolicyBullets extends StatelessWidget {
  const _PolicyBullets(this.items);

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: Icon(Icons.circle, size: 6, color: tokens.accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: tokens.textSecondary,
                        height: 1.65,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PolicyLinkCard extends StatelessWidget {
  const _PolicyLinkCard({
    required this.label,
    required this.uri,
    required this.onOpen,
    super.key,
  });

  final String label;
  final Uri uri;
  final Future<void> Function(BuildContext context, Uri uri) onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Material(
        color: tokens.primary.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: tokens.primary.withValues(alpha: 0.30)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onOpen(context, uri),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(Icons.open_in_new_rounded, color: tokens.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.accent,
                      fontWeight: FontWeight.w900,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_left_rounded, color: tokens.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AcceptanceCard extends StatelessWidget {
  const _AcceptanceCard({required this.tokens});

  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceSoft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'باستخدام هذا التطبيق، فإنك توافق على جمع واستخدام المعلومات وفقاً لسياسة الخصوصية هذه.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: tokens.textSecondary,
            fontWeight: FontWeight.w700,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
