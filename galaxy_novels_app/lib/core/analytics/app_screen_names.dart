abstract final class AppScreenNames {
  static const home = 'home';
  static const library = 'library';
  static const readerJourney = 'reader_journey';
  static const rankings = 'rankings';
  static const account = 'account';
  static const history = 'history';
  static const novelDetails = 'novel_details';
  static const reader = 'reader';
  static const allChapters = 'all_chapters';
  static const favorites = 'favorites';
  static const settings = 'settings';
  static const homeCustomization = 'home_customization';
  static const libraryCustomization = 'library_customization';
  static const readerSettings = 'reader_settings';
  static const advancedTerminology = 'advanced_terminology';
  static const downloads = 'downloads';
  static const downloadedNovel = 'downloaded_novel';
  static const dataManagement = 'data_management';
  static const about = 'about';
  static const privacy = 'privacy';
  static const componentGallery = 'component_gallery';

  static const values = <String>[
    home,
    library,
    readerJourney,
    rankings,
    account,
    history,
    novelDetails,
    reader,
    allChapters,
    favorites,
    settings,
    homeCustomization,
    libraryCustomization,
    readerSettings,
    advancedTerminology,
    downloads,
    downloadedNovel,
    dataManagement,
    about,
    privacy,
    componentGallery,
  ];

  static bool contains(String? name) => name != null && values.contains(name);
}
