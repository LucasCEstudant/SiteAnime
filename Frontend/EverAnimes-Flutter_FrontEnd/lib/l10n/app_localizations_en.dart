// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'EverAnimes';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get create => 'Create';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get remove => 'Remove';

  @override
  String get required => 'Required';

  @override
  String get invalidUrl => 'Invalid URL';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get enterEmail => 'Enter your email.';

  @override
  String get enterPassword => 'Enter your password.';

  @override
  String get passwordMinLength => 'Minimum 6 characters';

  @override
  String get passwordMinLengthError =>
      'Password must be at least 6 characters.';

  @override
  String get passwordMismatch => 'Passwords do not match.';

  @override
  String get rateLimitError =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get rateLimitErrorShort => 'Too many requests. Please wait a moment.';

  @override
  String get unexpectedError => 'Unexpected error. Please try again.';

  @override
  String get reload => 'Reload';

  @override
  String get login => 'Sign In';

  @override
  String get logout => 'Sign Out';

  @override
  String get tryAgain => 'Try again';

  @override
  String get url => 'URL';

  @override
  String get title => 'Title';

  @override
  String get site => 'Site';

  @override
  String get year => 'Year';

  @override
  String get status => 'Status';

  @override
  String get add => 'Add';

  @override
  String get filter => 'Filter';

  @override
  String get all => 'All';

  @override
  String get overview => 'Overview';

  @override
  String get episodes => 'Episodes';

  @override
  String get similar => 'Similar';

  @override
  String get links => 'Links';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get pageNotFound => '404 – Page not found';

  @override
  String get unexpectedErrorFallback => 'An unexpected error occurred';

  @override
  String get viewAll => 'View all';

  @override
  String get myList => 'My list';

  @override
  String watchAnime(String title) {
    return 'Watch $title';
  }

  @override
  String get loadingFeaturedContent => 'Loading featured content';

  @override
  String get continueWatching => 'Continue Watching';

  @override
  String get headerBrowse => 'Browse';

  @override
  String get headerMangas => 'Manga';

  @override
  String get headerSearchHint => 'Search anime…';

  @override
  String get headerNotifications => 'Notifications';

  @override
  String get headerMyList => 'My List';

  @override
  String get headerProfile => 'Profile';

  @override
  String get headerAdmin => 'Admin';

  @override
  String get homeCurrentSeason => 'Current Season';

  @override
  String get homeFeaturedCover => 'Featured anime cover';

  @override
  String get homeAddToList => 'Add to list';

  @override
  String get homeWatchNow => 'WATCH NOW';

  @override
  String get homeFeaturedBadge => 'FEATURED';

  @override
  String get homeDetails => 'Details';

  @override
  String get homeSimilarDev => 'Similar anime search is under development.';

  @override
  String get homeLoadingSynopsis => 'Loading synopsis…';

  @override
  String get homeErrorSynopsis => 'Could not load the synopsis.';

  @override
  String get homeEmptySynopsis => 'Synopsis not available.';

  @override
  String get homeLoadingEpisodes => 'Loading episodes…';

  @override
  String get homeErrorEpisodes => 'Error loading episodes.';

  @override
  String get homeEmptyEpisodes => 'No streaming episodes available.';

  @override
  String get homeLoadingLinks => 'Loading links…';

  @override
  String get homeErrorLinks => 'Error loading links.';

  @override
  String get homeEmptyLinks => 'No external links available.';

  @override
  String get homeCloseFeatured => 'Close featured';

  @override
  String searchFilterByGenre(String genre) {
    return 'Filtering by: $genre';
  }

  @override
  String searchFilterByYear(String year) {
    return 'Filtering by year: $year';
  }

  @override
  String get searchHintDefault => 'E.g.: Naruto, Dragon Ball...';

  @override
  String get searchError => 'Error searching anime';

  @override
  String get searchSelectGenre => 'Select a genre or type to search';

  @override
  String searchNoResults(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get searchGenres => 'Genres';

  @override
  String get searchGenresError => 'Error loading genres';

  @override
  String get searchSuggestionsError => 'Error loading suggestions';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginHeading => 'Sign in to your account';

  @override
  String get loginWrongCredentials => 'Incorrect email or password.';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get loginCreateAccount => 'Create account';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerHeading => 'Create a new account';

  @override
  String get registerEmailExists => 'This email is already registered.';

  @override
  String get registerSuccess => 'Account created successfully! Signing in...';

  @override
  String get registerHasAccount => 'Already have an account?';

  @override
  String get profileLogoutTitle => 'Sign out';

  @override
  String get profileLogoutConfirm => 'Are you sure you want to sign out?';

  @override
  String get profileUser => 'User';

  @override
  String get profileAdmin => 'Administrator';

  @override
  String get profileRegularUser => 'Regular user';

  @override
  String get profileAccountInfo => 'Account Information';

  @override
  String get profileAccessRole => 'Access role';

  @override
  String get profileSessionStatus => 'Session status';

  @override
  String get profileSessionActive => 'Active';

  @override
  String get profileActions => 'Actions';

  @override
  String get profileAdminPanel => 'Admin Panel';

  @override
  String get profileManageDesc => 'Manage users and anime';

  @override
  String get profileHomePage => 'Home page';

  @override
  String get profileSearchAnimes => 'Search anime';

  @override
  String get detailsLoadError => 'Error loading details';

  @override
  String get detailsEmptySynopsis => 'Synopsis not available.';

  @override
  String get detailsEmptyEpisodes => 'No streaming episodes available.';

  @override
  String get detailsEmptyLinks => 'No external links available.';

  @override
  String get detailsSimilarSoon => 'Similar titles coming soon.';

  @override
  String get playerLoadError => 'Error loading episode';

  @override
  String get playerEmptyEpisodes => 'No episodes available';

  @override
  String get playerPrevEpisode => 'Previous episode';

  @override
  String playerEpisodeCount(String current, String total) {
    return 'Episode $current of $total';
  }

  @override
  String get playerNextEpisode => 'Next episode';

  @override
  String get genresLoadError => 'Error loading genres';

  @override
  String get genresEmpty => 'No genres found.';

  @override
  String get mangasTitle => 'Manga';

  @override
  String get mangasInDevelopment => 'Under development';

  @override
  String get mangasDescription =>
      'We are preparing an amazing manga reading experience. It will be available soon!';

  @override
  String mangasProgress(String progress) {
    return 'Estimated progress: $progress%';
  }

  @override
  String get adminPanelTitle => 'Admin Panel';

  @override
  String get adminArea => 'Administrative Area';

  @override
  String adminLoggedAs(String email) {
    return 'Logged in as $email';
  }

  @override
  String get adminManagement => 'Management';

  @override
  String get adminManageUsers => 'Manage Users';

  @override
  String get adminManageUsersDesc => 'Create, edit and remove users';

  @override
  String get adminManageAnimes => 'Manage Anime';

  @override
  String get adminManageAnimesDesc => 'Local anime CRUD';

  @override
  String get adminApiTest => 'API Test';

  @override
  String get adminApiTestDesc => 'Diagnostics and endpoint tests';

  @override
  String get adminNavigation => 'Navigation';

  @override
  String get adminHomePage => 'Home Page';

  @override
  String get adminMyProfile => 'My Profile';

  @override
  String get adminAnimesNewAnime => 'New Anime';

  @override
  String get adminAnimesLoadError => 'Error loading anime';

  @override
  String get adminAnimesEmpty => 'No anime found.';

  @override
  String get adminAnimesCreateTitle => 'Create Anime';

  @override
  String get adminAnimesEditTitle => 'Edit Anime';

  @override
  String adminAnimesCreated(String date) {
    return 'Created $date';
  }

  @override
  String get adminAnimesBasicData => 'Basic Data';

  @override
  String get adminAnimesTitleLabel => 'Title *';

  @override
  String get adminAnimesTitleRequired => 'Title is required';

  @override
  String get adminAnimesSynopsis => 'Synopsis';

  @override
  String get adminAnimesInvalidYear => 'Invalid year';

  @override
  String get adminAnimesMinYear => 'Min. 1900';

  @override
  String adminAnimesMaxYear(String year) {
    return 'Max. $year';
  }

  @override
  String get adminAnimesScore => 'Score (0–10)';

  @override
  String get adminAnimesInvalid => 'Invalid';

  @override
  String get adminAnimesScoreRange => '0–10';

  @override
  String get adminAnimesCoverUrl => 'Cover URL';

  @override
  String get adminAnimesLocalDetails => 'Local Details';

  @override
  String get adminAnimesEpisodeCount => 'Episode Count';

  @override
  String get adminAnimesEpisodeRange => '0–5000';

  @override
  String get adminAnimesDuration => 'Duration (min)';

  @override
  String get adminAnimesDurationRange => '1–300';

  @override
  String get adminAnimesExternalLinks => 'External Links';

  @override
  String get adminAnimesStreamingEpisodes => 'Streaming Episodes';

  @override
  String get adminAnimesDeleteTitle => 'Delete Anime';

  @override
  String get adminAnimesDeleteConfirm =>
      'Are you sure you want to delete this anime?';

  @override
  String adminAnimesDeleteYear(String year) {
    return 'Year: $year';
  }

  @override
  String get adminAnimesDeleteWarning => 'This action cannot be undone.';

  @override
  String get adminUsersNewUser => 'New User';

  @override
  String get adminUsersLoadError => 'Error loading users';

  @override
  String get adminUsersEmpty => 'No users found.';

  @override
  String get adminUsersCreateTitle => 'Create User';

  @override
  String get adminUsersEditTitle => 'Edit User';

  @override
  String adminUsersCreatedAt(String date) {
    return 'Created on $date';
  }

  @override
  String get adminUsersEmailRequired => 'Email is required';

  @override
  String get adminUsersNewPassword => 'New password (leave blank to keep)';

  @override
  String get adminUsersPasswordRequired => 'Password is required';

  @override
  String get adminUsersRole => 'Role';

  @override
  String get adminUsersDeleteTitle => 'Delete User';

  @override
  String get adminUsersDeleteConfirm =>
      'Are you sure you want to delete this user?';

  @override
  String adminUsersDeleteRole(String role) {
    return 'Role: $role';
  }

  @override
  String get adminUsersDeleteWarning => 'This action cannot be undone.';

  @override
  String get apiTestTitle => 'API Test';

  @override
  String apiTestUnexpectedError(String error) {
    return 'Unexpected error: $error';
  }

  @override
  String get apiTestRepeat => 'Repeat tests';

  @override
  String get accessDeniedTitle => 'Access Denied';

  @override
  String get accessDeniedMessage =>
      'You do not have permission to access this page.\nThis area is restricted to administrators.';

  @override
  String footerCopyright(String year) {
    return '© $year EverAnimes. All rights reserved.';
  }

  @override
  String get footerDescription =>
      'Your favorite anime platform.\nDiscover, explore and follow thousands of titles\nwith detailed information from multiple sources.';

  @override
  String get footerGithub => 'GitHub';

  @override
  String get footerWebsite => 'Website';

  @override
  String get footerContact => 'Contact';

  @override
  String get footerNavigation => 'Navigation';

  @override
  String get footerHome => 'Home';

  @override
  String get footerSearch => 'Search';

  @override
  String get footerExploreGenres => 'Explore Genres';

  @override
  String get footerCurrentSeason => 'Current Season';

  @override
  String get footerResources => 'Resources';

  @override
  String get footerApiAniList => 'API AniList';

  @override
  String get footerApiMal => 'API MyAnimeList';

  @override
  String get footerApiKitsu => 'API Kitsu';

  @override
  String get footerDocs => 'Documentation';

  @override
  String get footerAbout => 'About';

  @override
  String get footerPortfolio => 'Portfolio Project';

  @override
  String get footerOpenSource => 'Open Source';

  @override
  String get footerTerms => 'Terms of Use';

  @override
  String get footerPrivacy => 'Privacy';

  @override
  String get addedToList => 'Added to your list!';

  @override
  String get alreadyInList => 'This anime is already in your list.';

  @override
  String get addToListError => 'Failed to add to list. Please try again.';

  @override
  String get myListEmpty => 'Your list is empty. Add animes to get started!';

  @override
  String get myListRemoveConfirm =>
      'Are you sure you want to remove this anime from your list?';

  @override
  String get myListRemoved => 'Removed from your list.';

  @override
  String get myListStatusWatching => 'Watching';

  @override
  String get myListStatusCompleted => 'Completed';

  @override
  String get myListStatusPlanToWatch => 'Plan to Watch';

  @override
  String get myListStatusDropped => 'Dropped';

  @override
  String get myListStatusOnHold => 'On Hold';

  @override
  String get myListEditorMode => 'Editor mode';

  @override
  String get myListExitEditor => 'Exit editor';

  @override
  String get myListSortAZ => 'A → Z';

  @override
  String get myListSortZA => 'Z → A';

  @override
  String get myListSortYearDesc => 'Year ↓';

  @override
  String get myListSortYearAsc => 'Year ↑';

  @override
  String get myListSortDateAdded => 'Recently added';

  @override
  String get myListSortDateUpdated => 'Recently updated';

  @override
  String get myListSelectAll => 'Select all';

  @override
  String get myListDeselectAll => 'Deselect';

  @override
  String myListSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get myListChangeStatus => 'Change status';

  @override
  String myListItemsUpdated(int count) {
    return '$count items updated';
  }

  @override
  String get myListUpdated => 'Updated successfully';

  @override
  String get myListScore => 'Score (0–10)';

  @override
  String get myListEpisodesWatched => 'Episodes watched';

  @override
  String get myListNotes => 'Notes';
}
