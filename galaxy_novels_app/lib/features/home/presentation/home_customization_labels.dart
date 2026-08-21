import '../domain/home_customization.dart';

String homeSectionTitle(HomeSectionId section) => switch (section) {
  HomeSectionId.continueReading => 'أكمل القراءة',
  HomeSectionId.becauseYouRead => 'لأنك قرأت…',
  HomeSectionId.updatedNovels => 'روايات محدثة',
  HomeSectionId.latestUpdates => 'آخر تحديثات الروايات',
};

String homePresetTitle(HomeCustomizationPreset preset) => switch (preset) {
  HomeCustomizationPreset.balanced => 'متوازن',
  HomeCustomizationPreset.quick => 'سريع',
  HomeCustomizationPreset.visual => 'بصري',
};

String homePresetDescription(HomeCustomizationPreset preset) =>
    switch (preset) {
      HomeCustomizationPreset.balanced => 'تفاصيل واضحة ومسافات متوازنة',
      HomeCustomizationPreset.quick => 'بطاقات أصغر ومحتوى أسرع',
      HomeCustomizationPreset.visual => 'أغلفة بارزة ولوحات ناعمة',
    };

String homeDensityTitle(HomeDensity value) => switch (value) {
  HomeDensity.compact => 'مضغوط',
  HomeDensity.balanced => 'متوازن',
  HomeDensity.comfortable => 'مريح',
};

String homeHeaderStyleTitle(HomeHeaderStyle value) => switch (value) {
  HomeHeaderStyle.standard => 'بالأيقونة',
  HomeHeaderStyle.simple => 'مبسّط',
};

String homeCoverCornerTitle(HomeCoverCorner value) => switch (value) {
  HomeCoverCorner.soft => 'ناعم',
  HomeCoverCorner.medium => 'متوسط',
  HomeCoverCorner.almostSquare => 'شبه مستقيم',
};

String homeCardSurfaceTitle(HomeCardSurface value) => switch (value) {
  HomeCardSurface.flat => 'مسطّح',
  HomeCardSurface.outlined => 'بإطار',
  HomeCardSurface.elevated => 'بارز',
};

String homeCardTintTitle(HomeCardTint value) => switch (value) {
  HomeCardTint.neutral => 'محايدة',
  HomeCardTint.subtle => 'خفيفة',
  HomeCardTint.strong => 'واضحة',
};

String homeProgressStyleTitle(HomeProgressStyle value) => switch (value) {
  HomeProgressStyle.bar => 'شريط',
  HomeProgressStyle.ring => 'حلقة',
  HomeProgressStyle.percentage => 'نسبة',
  HomeProgressStyle.hidden => 'مخفي',
};

String homeCardSizeTitle(HomeCardSize value) => switch (value) {
  HomeCardSize.small => 'صغير',
  HomeCardSize.medium => 'متوسط',
  HomeCardSize.large => 'كبير',
};

String homeCoverPresentationTitle(HomeCoverPresentation value) =>
    switch (value) {
      HomeCoverPresentation.fill => 'ملء الإطار',
      HomeCoverPresentation.fit => 'الغلاف كاملًا',
      HomeCoverPresentation.tonalFrame => 'إطار لوني',
    };

String homeSectionContainerTitle(HomeSectionContainer value) => switch (value) {
  HomeSectionContainer.open => 'مفتوحة',
  HomeSectionContainer.softPanel => 'لوحة ناعمة',
};

String homeItemCountTitle(HomeItemCount value) => switch (value) {
  HomeItemCount.few => 'قليل',
  HomeItemCount.medium => 'متوسط',
  HomeItemCount.all => 'كل المتاح',
};

String homeContinueTemplateTitle(ContinueReadingCardTemplate value) =>
    switch (value) {
      ContinueReadingCardTemplate.detailed => 'تفصيلية',
      ContinueReadingCardTemplate.compactStrip => 'شريط سريع',
      ContinueReadingCardTemplate.coverFocus => 'غلاف بارز',
    };

String homeUpdatedTemplateTitle(UpdatedNovelCardTemplate value) =>
    switch (value) {
      UpdatedNovelCardTemplate.poster => 'بوستر',
      UpdatedNovelCardTemplate.horizontal => 'أفقي',
      UpdatedNovelCardTemplate.coverOnly => 'غلاف فقط',
    };

String homeRecommendedTemplateTitle(RecommendedNovelCardTemplate value) =>
    switch (value) {
      RecommendedNovelCardTemplate.poster => 'بوستر',
      RecommendedNovelCardTemplate.horizontal => 'أفقي',
      RecommendedNovelCardTemplate.coverOnly => 'غلاف فقط',
    };

String homeLatestTemplateTitle(LatestUpdateCardTemplate value) =>
    switch (value) {
      LatestUpdateCardTemplate.detailed => 'تفصيلي',
      LatestUpdateCardTemplate.compact => 'مختصر',
      LatestUpdateCardTemplate.poster => 'بوستر',
    };

String homeUpdatedLayoutTitle(UpdatedNovelsLayout value) => switch (value) {
  UpdatedNovelsLayout.horizontalStrip => 'شريط أفقي',
  UpdatedNovelsLayout.grid => 'شبكة',
};

String homeRecommendedLayoutTitle(RecommendedNovelsLayout value) =>
    switch (value) {
      RecommendedNovelsLayout.horizontalStrip => 'شريط أفقي',
      RecommendedNovelsLayout.grid => 'شبكة',
    };

String homeLatestLayoutTitle(LatestUpdatesLayout value) => switch (value) {
  LatestUpdatesLayout.horizontalStrip => 'شريط أغلفة',
  LatestUpdatesLayout.detailedList => 'قائمة',
  LatestUpdatesLayout.grid => 'شبكة',
};

String homeFieldTitle(HomeCardField value) => switch (value) {
  HomeCardField.chapter => 'اسم الفصل',
  HomeCardField.progress => 'مؤشر التقدم',
  HomeCardField.status => 'الحالة',
  HomeCardField.chapterCount => 'عدد الفصول',
  HomeCardField.firstGenre => 'أول تصنيف',
  HomeCardField.date => 'التاريخ',
  HomeCardField.secondChapter => 'الفصل الثاني',
  HomeCardField.matchReason => 'سبب الاقتراح',
};

String homeTemplateSummary(HomeSectionId section, HomeCustomization value) =>
    switch (section) {
      HomeSectionId.continueReading => homeContinueTemplateTitle(
        value.continueReadingTemplate,
      ),
      HomeSectionId.becauseYouRead => homeRecommendedTemplateTitle(
        value.recommendedNovelsTemplate,
      ),
      HomeSectionId.updatedNovels => homeUpdatedTemplateTitle(
        value.updatedNovelsTemplate,
      ),
      HomeSectionId.latestUpdates => homeLatestTemplateTitle(
        value.latestUpdatesTemplate,
      ),
    };
