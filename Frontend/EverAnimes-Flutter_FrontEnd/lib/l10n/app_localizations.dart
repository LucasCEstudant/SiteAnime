import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'EverAnimes'**
  String get appTitle;

  /// No description provided for @back.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get save;

  /// No description provided for @create.
  ///
  /// In pt, this message translates to:
  /// **'Criar'**
  String get create;

  /// No description provided for @edit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get remove;

  /// No description provided for @required.
  ///
  /// In pt, this message translates to:
  /// **'Obrigatório'**
  String get required;

  /// No description provided for @invalidUrl.
  ///
  /// In pt, this message translates to:
  /// **'URL inválida'**
  String get invalidUrl;

  /// No description provided for @invalidEmail.
  ///
  /// In pt, this message translates to:
  /// **'Email inválido'**
  String get invalidEmail;

  /// No description provided for @email.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Senha'**
  String get confirmPassword;

  /// No description provided for @enterEmail.
  ///
  /// In pt, this message translates to:
  /// **'Informe o email.'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In pt, this message translates to:
  /// **'Informe a senha.'**
  String get enterPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get passwordMinLength;

  /// No description provided for @passwordMinLengthError.
  ///
  /// In pt, this message translates to:
  /// **'A senha deve ter pelo menos 6 caracteres.'**
  String get passwordMinLengthError;

  /// No description provided for @passwordMismatch.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não coincidem.'**
  String get passwordMismatch;

  /// No description provided for @rateLimitError.
  ///
  /// In pt, this message translates to:
  /// **'Muitas tentativas. Aguarde um momento e tente novamente.'**
  String get rateLimitError;

  /// No description provided for @rateLimitErrorShort.
  ///
  /// In pt, this message translates to:
  /// **'Muitas requisições. Aguarde um momento.'**
  String get rateLimitErrorShort;

  /// No description provided for @unexpectedError.
  ///
  /// In pt, this message translates to:
  /// **'Erro inesperado. Tente novamente.'**
  String get unexpectedError;

  /// No description provided for @reload.
  ///
  /// In pt, this message translates to:
  /// **'Recarregar'**
  String get reload;

  /// No description provided for @login.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get logout;

  /// No description provided for @tryAgain.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get tryAgain;

  /// No description provided for @url.
  ///
  /// In pt, this message translates to:
  /// **'URL'**
  String get url;

  /// No description provided for @title.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get title;

  /// No description provided for @site.
  ///
  /// In pt, this message translates to:
  /// **'Site'**
  String get site;

  /// No description provided for @year.
  ///
  /// In pt, this message translates to:
  /// **'Ano'**
  String get year;

  /// No description provided for @status.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @add.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get add;

  /// No description provided for @filter.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar'**
  String get filter;

  /// No description provided for @all.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get all;

  /// No description provided for @overview.
  ///
  /// In pt, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @episodes.
  ///
  /// In pt, this message translates to:
  /// **'Episódios'**
  String get episodes;

  /// No description provided for @similar.
  ///
  /// In pt, this message translates to:
  /// **'Similares'**
  String get similar;

  /// No description provided for @links.
  ///
  /// In pt, this message translates to:
  /// **'Links'**
  String get links;

  /// No description provided for @backToHome.
  ///
  /// In pt, this message translates to:
  /// **'Voltar para Home'**
  String get backToHome;

  /// No description provided for @pageNotFound.
  ///
  /// In pt, this message translates to:
  /// **'404 – Página não encontrada'**
  String get pageNotFound;

  /// No description provided for @unexpectedErrorFallback.
  ///
  /// In pt, this message translates to:
  /// **'Ocorreu um erro inesperado'**
  String get unexpectedErrorFallback;

  /// No description provided for @viewAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver tudo'**
  String get viewAll;

  /// No description provided for @myList.
  ///
  /// In pt, this message translates to:
  /// **'Minha lista'**
  String get myList;

  /// No description provided for @watchAnime.
  ///
  /// In pt, this message translates to:
  /// **'Assistir {title}'**
  String watchAnime(String title);

  /// No description provided for @loadingFeaturedContent.
  ///
  /// In pt, this message translates to:
  /// **'Carregando conteúdo em destaque'**
  String get loadingFeaturedContent;

  /// No description provided for @continueWatching.
  ///
  /// In pt, this message translates to:
  /// **'Continue Assistindo'**
  String get continueWatching;

  /// No description provided for @headerBrowse.
  ///
  /// In pt, this message translates to:
  /// **'Explorar'**
  String get headerBrowse;

  /// No description provided for @headerMangas.
  ///
  /// In pt, this message translates to:
  /// **'Mangás'**
  String get headerMangas;

  /// No description provided for @headerSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar anime…'**
  String get headerSearchHint;

  /// No description provided for @headerNotifications.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get headerNotifications;

  /// No description provided for @headerMyList.
  ///
  /// In pt, this message translates to:
  /// **'Minha Lista'**
  String get headerMyList;

  /// No description provided for @headerProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get headerProfile;

  /// No description provided for @headerAdmin.
  ///
  /// In pt, this message translates to:
  /// **'Admin'**
  String get headerAdmin;

  /// No description provided for @homeCurrentSeason.
  ///
  /// In pt, this message translates to:
  /// **'Temporada Atual'**
  String get homeCurrentSeason;

  /// No description provided for @homeFeaturedCover.
  ///
  /// In pt, this message translates to:
  /// **'Capa do anime em destaque'**
  String get homeFeaturedCover;

  /// No description provided for @homeAddToList.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar à lista'**
  String get homeAddToList;

  /// No description provided for @homeWatchNow.
  ///
  /// In pt, this message translates to:
  /// **'ASSISTIR AGORA'**
  String get homeWatchNow;

  /// No description provided for @homeFeaturedBadge.
  ///
  /// In pt, this message translates to:
  /// **'EM DESTAQUE'**
  String get homeFeaturedBadge;

  /// No description provided for @homeDetails.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes'**
  String get homeDetails;

  /// No description provided for @homeSimilarDev.
  ///
  /// In pt, this message translates to:
  /// **'Busca de animes similares em desenvolvimento.'**
  String get homeSimilarDev;

  /// No description provided for @homeLoadingSynopsis.
  ///
  /// In pt, this message translates to:
  /// **'Carregando sinopse…'**
  String get homeLoadingSynopsis;

  /// No description provided for @homeErrorSynopsis.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar a sinopse.'**
  String get homeErrorSynopsis;

  /// No description provided for @homeEmptySynopsis.
  ///
  /// In pt, this message translates to:
  /// **'Sinopse não disponível.'**
  String get homeEmptySynopsis;

  /// No description provided for @homeLoadingEpisodes.
  ///
  /// In pt, this message translates to:
  /// **'Carregando episódios…'**
  String get homeLoadingEpisodes;

  /// No description provided for @homeErrorEpisodes.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar episódios.'**
  String get homeErrorEpisodes;

  /// No description provided for @homeEmptyEpisodes.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum episódio de streaming disponível.'**
  String get homeEmptyEpisodes;

  /// No description provided for @homeLoadingLinks.
  ///
  /// In pt, this message translates to:
  /// **'Carregando links…'**
  String get homeLoadingLinks;

  /// No description provided for @homeErrorLinks.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar links.'**
  String get homeErrorLinks;

  /// No description provided for @homeEmptyLinks.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum link externo disponível.'**
  String get homeEmptyLinks;

  /// No description provided for @homeCloseFeatured.
  ///
  /// In pt, this message translates to:
  /// **'Fechar destaque'**
  String get homeCloseFeatured;

  /// No description provided for @searchFilterByGenre.
  ///
  /// In pt, this message translates to:
  /// **'Filtrando por: {genre}'**
  String searchFilterByGenre(String genre);

  /// No description provided for @searchFilterByYear.
  ///
  /// In pt, this message translates to:
  /// **'Filtrando por ano: {year}'**
  String searchFilterByYear(String year);

  /// No description provided for @searchHintDefault.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Naruto, Dragon Ball...'**
  String get searchHintDefault;

  /// No description provided for @searchError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao buscar animes'**
  String get searchError;

  /// No description provided for @searchSelectGenre.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um gênero ou digite para buscar'**
  String get searchSelectGenre;

  /// No description provided for @searchNoResults.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum resultado para \"{query}\"'**
  String searchNoResults(String query);

  /// No description provided for @searchGenres.
  ///
  /// In pt, this message translates to:
  /// **'Gêneros'**
  String get searchGenres;

  /// No description provided for @searchGenresError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar gêneros'**
  String get searchGenresError;

  /// No description provided for @searchSuggestionsError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar sugestões'**
  String get searchSuggestionsError;

  /// No description provided for @loginTitle.
  ///
  /// In pt, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @loginHeading.
  ///
  /// In pt, this message translates to:
  /// **'Entrar na sua conta'**
  String get loginHeading;

  /// No description provided for @loginWrongCredentials.
  ///
  /// In pt, this message translates to:
  /// **'Email ou senha incorretos.'**
  String get loginWrongCredentials;

  /// No description provided for @loginNoAccount.
  ///
  /// In pt, this message translates to:
  /// **'Não tem conta?'**
  String get loginNoAccount;

  /// No description provided for @loginCreateAccount.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get loginCreateAccount;

  /// No description provided for @registerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar Conta'**
  String get registerTitle;

  /// No description provided for @registerHeading.
  ///
  /// In pt, this message translates to:
  /// **'Criar nova conta'**
  String get registerHeading;

  /// No description provided for @registerEmailExists.
  ///
  /// In pt, this message translates to:
  /// **'Este email já está cadastrado.'**
  String get registerEmailExists;

  /// No description provided for @registerSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Conta criada com sucesso! Entrando...'**
  String get registerSuccess;

  /// No description provided for @registerHasAccount.
  ///
  /// In pt, this message translates to:
  /// **'Já tem uma conta?'**
  String get registerHasAccount;

  /// No description provided for @profileLogoutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sair da conta'**
  String get profileLogoutTitle;

  /// No description provided for @profileLogoutConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja fazer logout?'**
  String get profileLogoutConfirm;

  /// No description provided for @profileUser.
  ///
  /// In pt, this message translates to:
  /// **'Usuário'**
  String get profileUser;

  /// No description provided for @profileAdmin.
  ///
  /// In pt, this message translates to:
  /// **'Administrador'**
  String get profileAdmin;

  /// No description provided for @profileRegularUser.
  ///
  /// In pt, this message translates to:
  /// **'Usuário comum'**
  String get profileRegularUser;

  /// No description provided for @profileAccountInfo.
  ///
  /// In pt, this message translates to:
  /// **'Informações da Conta'**
  String get profileAccountInfo;

  /// No description provided for @profileAccessRole.
  ///
  /// In pt, this message translates to:
  /// **'Perfil de acesso'**
  String get profileAccessRole;

  /// No description provided for @profileSessionStatus.
  ///
  /// In pt, this message translates to:
  /// **'Status da sessão'**
  String get profileSessionStatus;

  /// No description provided for @profileSessionActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativa'**
  String get profileSessionActive;

  /// No description provided for @profileActions.
  ///
  /// In pt, this message translates to:
  /// **'Ações'**
  String get profileActions;

  /// No description provided for @profileAdminPanel.
  ///
  /// In pt, this message translates to:
  /// **'Painel Admin'**
  String get profileAdminPanel;

  /// No description provided for @profileManageDesc.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar usuários e animes'**
  String get profileManageDesc;

  /// No description provided for @profileHomePage.
  ///
  /// In pt, this message translates to:
  /// **'Página inicial'**
  String get profileHomePage;

  /// No description provided for @profileSearchAnimes.
  ///
  /// In pt, this message translates to:
  /// **'Buscar animes'**
  String get profileSearchAnimes;

  /// No description provided for @detailsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar detalhes'**
  String get detailsLoadError;

  /// No description provided for @detailsEmptySynopsis.
  ///
  /// In pt, this message translates to:
  /// **'Sinopse não disponível.'**
  String get detailsEmptySynopsis;

  /// No description provided for @detailsEmptyEpisodes.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum episódio de streaming disponível.'**
  String get detailsEmptyEpisodes;

  /// No description provided for @detailsEmptyLinks.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum link externo disponível.'**
  String get detailsEmptyLinks;

  /// No description provided for @detailsSimilarSoon.
  ///
  /// In pt, this message translates to:
  /// **'Títulos similares em breve.'**
  String get detailsSimilarSoon;

  /// No description provided for @playerLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar episódio'**
  String get playerLoadError;

  /// No description provided for @playerEmptyEpisodes.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum episódio disponível'**
  String get playerEmptyEpisodes;

  /// No description provided for @playerPrevEpisode.
  ///
  /// In pt, this message translates to:
  /// **'Episódio anterior'**
  String get playerPrevEpisode;

  /// No description provided for @playerEpisodeCount.
  ///
  /// In pt, this message translates to:
  /// **'Episódio {current} de {total}'**
  String playerEpisodeCount(String current, String total);

  /// No description provided for @playerNextEpisode.
  ///
  /// In pt, this message translates to:
  /// **'Próximo episódio'**
  String get playerNextEpisode;

  /// No description provided for @genresLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar gêneros'**
  String get genresLoadError;

  /// No description provided for @genresEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum gênero encontrado.'**
  String get genresEmpty;

  /// No description provided for @mangasTitle.
  ///
  /// In pt, this message translates to:
  /// **'Mangás'**
  String get mangasTitle;

  /// No description provided for @mangasInDevelopment.
  ///
  /// In pt, this message translates to:
  /// **'Em desenvolvimento'**
  String get mangasInDevelopment;

  /// No description provided for @mangasDescription.
  ///
  /// In pt, this message translates to:
  /// **'Estamos preparando uma experiência incrível para leitura de mangás. Em breve estará disponível!'**
  String get mangasDescription;

  /// No description provided for @mangasProgress.
  ///
  /// In pt, this message translates to:
  /// **'Progresso estimado: {progress}%'**
  String mangasProgress(String progress);

  /// No description provided for @adminPanelTitle.
  ///
  /// In pt, this message translates to:
  /// **'Painel Admin'**
  String get adminPanelTitle;

  /// No description provided for @adminArea.
  ///
  /// In pt, this message translates to:
  /// **'Área Administrativa'**
  String get adminArea;

  /// No description provided for @adminLoggedAs.
  ///
  /// In pt, this message translates to:
  /// **'Logado como {email}'**
  String adminLoggedAs(String email);

  /// No description provided for @adminManagement.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciamento'**
  String get adminManagement;

  /// No description provided for @adminManageUsers.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar Usuários'**
  String get adminManageUsers;

  /// No description provided for @adminManageUsersDesc.
  ///
  /// In pt, this message translates to:
  /// **'Criar, editar e remover usuários'**
  String get adminManageUsersDesc;

  /// No description provided for @adminManageAnimes.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar Animes'**
  String get adminManageAnimes;

  /// No description provided for @adminManageAnimesDesc.
  ///
  /// In pt, this message translates to:
  /// **'CRUD de animes locais'**
  String get adminManageAnimesDesc;

  /// No description provided for @adminApiTest.
  ///
  /// In pt, this message translates to:
  /// **'Teste API'**
  String get adminApiTest;

  /// No description provided for @adminApiTestDesc.
  ///
  /// In pt, this message translates to:
  /// **'Diagnóstico e testes de endpoints'**
  String get adminApiTestDesc;

  /// No description provided for @adminNavigation.
  ///
  /// In pt, this message translates to:
  /// **'Navegação'**
  String get adminNavigation;

  /// No description provided for @adminHomePage.
  ///
  /// In pt, this message translates to:
  /// **'Página Inicial'**
  String get adminHomePage;

  /// No description provided for @adminMyProfile.
  ///
  /// In pt, this message translates to:
  /// **'Meu Perfil'**
  String get adminMyProfile;

  /// No description provided for @adminAnimesNewAnime.
  ///
  /// In pt, this message translates to:
  /// **'Novo Anime'**
  String get adminAnimesNewAnime;

  /// No description provided for @adminAnimesLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar animes'**
  String get adminAnimesLoadError;

  /// No description provided for @adminAnimesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum anime encontrado.'**
  String get adminAnimesEmpty;

  /// No description provided for @adminAnimesCreateTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar Anime'**
  String get adminAnimesCreateTitle;

  /// No description provided for @adminAnimesEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Anime'**
  String get adminAnimesEditTitle;

  /// No description provided for @adminAnimesCreated.
  ///
  /// In pt, this message translates to:
  /// **'Criado {date}'**
  String adminAnimesCreated(String date);

  /// No description provided for @adminAnimesBasicData.
  ///
  /// In pt, this message translates to:
  /// **'Dados Básicos'**
  String get adminAnimesBasicData;

  /// No description provided for @adminAnimesTitleLabel.
  ///
  /// In pt, this message translates to:
  /// **'Título *'**
  String get adminAnimesTitleLabel;

  /// No description provided for @adminAnimesTitleRequired.
  ///
  /// In pt, this message translates to:
  /// **'Título é obrigatório'**
  String get adminAnimesTitleRequired;

  /// No description provided for @adminAnimesSynopsis.
  ///
  /// In pt, this message translates to:
  /// **'Sinopse'**
  String get adminAnimesSynopsis;

  /// No description provided for @adminAnimesInvalidYear.
  ///
  /// In pt, this message translates to:
  /// **'Ano inválido'**
  String get adminAnimesInvalidYear;

  /// No description provided for @adminAnimesMinYear.
  ///
  /// In pt, this message translates to:
  /// **'Mín. 1900'**
  String get adminAnimesMinYear;

  /// No description provided for @adminAnimesMaxYear.
  ///
  /// In pt, this message translates to:
  /// **'Máx. {year}'**
  String adminAnimesMaxYear(String year);

  /// No description provided for @adminAnimesScore.
  ///
  /// In pt, this message translates to:
  /// **'Score (0–10)'**
  String get adminAnimesScore;

  /// No description provided for @adminAnimesInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Inválido'**
  String get adminAnimesInvalid;

  /// No description provided for @adminAnimesScoreRange.
  ///
  /// In pt, this message translates to:
  /// **'0–10'**
  String get adminAnimesScoreRange;

  /// No description provided for @adminAnimesCoverUrl.
  ///
  /// In pt, this message translates to:
  /// **'URL da capa'**
  String get adminAnimesCoverUrl;

  /// No description provided for @adminAnimesLocalDetails.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes Locais'**
  String get adminAnimesLocalDetails;

  /// No description provided for @adminAnimesEpisodeCount.
  ///
  /// In pt, this message translates to:
  /// **'Nº Episódios'**
  String get adminAnimesEpisodeCount;

  /// No description provided for @adminAnimesEpisodeRange.
  ///
  /// In pt, this message translates to:
  /// **'0–5000'**
  String get adminAnimesEpisodeRange;

  /// No description provided for @adminAnimesDuration.
  ///
  /// In pt, this message translates to:
  /// **'Duração (min)'**
  String get adminAnimesDuration;

  /// No description provided for @adminAnimesDurationRange.
  ///
  /// In pt, this message translates to:
  /// **'1–300'**
  String get adminAnimesDurationRange;

  /// No description provided for @adminAnimesExternalLinks.
  ///
  /// In pt, this message translates to:
  /// **'Links Externos'**
  String get adminAnimesExternalLinks;

  /// No description provided for @adminAnimesStreamingEpisodes.
  ///
  /// In pt, this message translates to:
  /// **'Episódios Streaming'**
  String get adminAnimesStreamingEpisodes;

  /// No description provided for @adminAnimesDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Anime'**
  String get adminAnimesDeleteTitle;

  /// No description provided for @adminAnimesDeleteConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja excluir o anime?'**
  String get adminAnimesDeleteConfirm;

  /// No description provided for @adminAnimesDeleteYear.
  ///
  /// In pt, this message translates to:
  /// **'Ano: {year}'**
  String adminAnimesDeleteYear(String year);

  /// No description provided for @adminAnimesDeleteWarning.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação não pode ser desfeita.'**
  String get adminAnimesDeleteWarning;

  /// No description provided for @adminUsersNewUser.
  ///
  /// In pt, this message translates to:
  /// **'Novo Usuário'**
  String get adminUsersNewUser;

  /// No description provided for @adminUsersLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar usuários'**
  String get adminUsersLoadError;

  /// No description provided for @adminUsersEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum usuário encontrado.'**
  String get adminUsersEmpty;

  /// No description provided for @adminUsersCreateTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar Usuário'**
  String get adminUsersCreateTitle;

  /// No description provided for @adminUsersEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Usuário'**
  String get adminUsersEditTitle;

  /// No description provided for @adminUsersCreatedAt.
  ///
  /// In pt, this message translates to:
  /// **'Criado em {date}'**
  String adminUsersCreatedAt(String date);

  /// No description provided for @adminUsersEmailRequired.
  ///
  /// In pt, this message translates to:
  /// **'Email é obrigatório'**
  String get adminUsersEmailRequired;

  /// No description provided for @adminUsersNewPassword.
  ///
  /// In pt, this message translates to:
  /// **'Nova senha (deixe vazio para manter)'**
  String get adminUsersNewPassword;

  /// No description provided for @adminUsersPasswordRequired.
  ///
  /// In pt, this message translates to:
  /// **'Senha é obrigatória'**
  String get adminUsersPasswordRequired;

  /// No description provided for @adminUsersRole.
  ///
  /// In pt, this message translates to:
  /// **'Role'**
  String get adminUsersRole;

  /// No description provided for @adminUsersDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Usuário'**
  String get adminUsersDeleteTitle;

  /// No description provided for @adminUsersDeleteConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja excluir o usuário?'**
  String get adminUsersDeleteConfirm;

  /// No description provided for @adminUsersDeleteRole.
  ///
  /// In pt, this message translates to:
  /// **'Role: {role}'**
  String adminUsersDeleteRole(String role);

  /// No description provided for @adminUsersDeleteWarning.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação não pode ser desfeita.'**
  String get adminUsersDeleteWarning;

  /// No description provided for @apiTestTitle.
  ///
  /// In pt, this message translates to:
  /// **'Teste de API'**
  String get apiTestTitle;

  /// No description provided for @apiTestUnexpectedError.
  ///
  /// In pt, this message translates to:
  /// **'Erro inesperado: {error}'**
  String apiTestUnexpectedError(String error);

  /// No description provided for @apiTestRepeat.
  ///
  /// In pt, this message translates to:
  /// **'Repetir testes'**
  String get apiTestRepeat;

  /// No description provided for @accessDeniedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Acesso Negado'**
  String get accessDeniedTitle;

  /// No description provided for @accessDeniedMessage.
  ///
  /// In pt, this message translates to:
  /// **'Você não tem permissão para acessar esta página.\nEsta área é restrita a administradores.'**
  String get accessDeniedMessage;

  /// No description provided for @footerCopyright.
  ///
  /// In pt, this message translates to:
  /// **'© {year} EverAnimes. Todos os direitos reservados.'**
  String footerCopyright(String year);

  /// No description provided for @footerDescription.
  ///
  /// In pt, this message translates to:
  /// **'Sua plataforma de animes favorita.\nDescubra, explore e acompanhe milhares de títulos\ncom informações detalhadas de várias fontes.'**
  String get footerDescription;

  /// No description provided for @footerGithub.
  ///
  /// In pt, this message translates to:
  /// **'GitHub'**
  String get footerGithub;

  /// No description provided for @footerWebsite.
  ///
  /// In pt, this message translates to:
  /// **'Website'**
  String get footerWebsite;

  /// No description provided for @footerContact.
  ///
  /// In pt, this message translates to:
  /// **'Contato'**
  String get footerContact;

  /// No description provided for @footerNavigation.
  ///
  /// In pt, this message translates to:
  /// **'Navegação'**
  String get footerNavigation;

  /// No description provided for @footerHome.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get footerHome;

  /// No description provided for @footerSearch.
  ///
  /// In pt, this message translates to:
  /// **'Buscar'**
  String get footerSearch;

  /// No description provided for @footerExploreGenres.
  ///
  /// In pt, this message translates to:
  /// **'Explorar Gêneros'**
  String get footerExploreGenres;

  /// No description provided for @footerCurrentSeason.
  ///
  /// In pt, this message translates to:
  /// **'Temporada Atual'**
  String get footerCurrentSeason;

  /// No description provided for @footerResources.
  ///
  /// In pt, this message translates to:
  /// **'Recursos'**
  String get footerResources;

  /// No description provided for @footerApiAniList.
  ///
  /// In pt, this message translates to:
  /// **'API AniList'**
  String get footerApiAniList;

  /// No description provided for @footerApiMal.
  ///
  /// In pt, this message translates to:
  /// **'API MyAnimeList'**
  String get footerApiMal;

  /// No description provided for @footerApiKitsu.
  ///
  /// In pt, this message translates to:
  /// **'API Kitsu'**
  String get footerApiKitsu;

  /// No description provided for @footerDocs.
  ///
  /// In pt, this message translates to:
  /// **'Documentação'**
  String get footerDocs;

  /// No description provided for @footerAbout.
  ///
  /// In pt, this message translates to:
  /// **'Sobre'**
  String get footerAbout;

  /// No description provided for @footerPortfolio.
  ///
  /// In pt, this message translates to:
  /// **'Projeto Portfolio'**
  String get footerPortfolio;

  /// No description provided for @footerOpenSource.
  ///
  /// In pt, this message translates to:
  /// **'Código Aberto'**
  String get footerOpenSource;

  /// No description provided for @footerTerms.
  ///
  /// In pt, this message translates to:
  /// **'Termos de Uso'**
  String get footerTerms;

  /// No description provided for @footerPrivacy.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade'**
  String get footerPrivacy;

  /// No description provided for @addedToList.
  ///
  /// In pt, this message translates to:
  /// **'Adicionado à sua lista!'**
  String get addedToList;

  /// No description provided for @alreadyInList.
  ///
  /// In pt, this message translates to:
  /// **'Este anime já está na sua lista.'**
  String get alreadyInList;

  /// No description provided for @addToListError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao adicionar à lista. Tente novamente.'**
  String get addToListError;

  /// No description provided for @myListEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Sua lista está vazia. Adicione animes para começar!'**
  String get myListEmpty;

  /// No description provided for @myListRemoveConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja remover este anime da sua lista?'**
  String get myListRemoveConfirm;

  /// No description provided for @myListRemoved.
  ///
  /// In pt, this message translates to:
  /// **'Removido da sua lista.'**
  String get myListRemoved;

  /// No description provided for @myListStatusWatching.
  ///
  /// In pt, this message translates to:
  /// **'Assistindo'**
  String get myListStatusWatching;

  /// No description provided for @myListStatusCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Completo'**
  String get myListStatusCompleted;

  /// No description provided for @myListStatusPlanToWatch.
  ///
  /// In pt, this message translates to:
  /// **'Planejo Assistir'**
  String get myListStatusPlanToWatch;

  /// No description provided for @myListStatusDropped.
  ///
  /// In pt, this message translates to:
  /// **'Abandonado'**
  String get myListStatusDropped;

  /// No description provided for @myListStatusOnHold.
  ///
  /// In pt, this message translates to:
  /// **'Em Pausa'**
  String get myListStatusOnHold;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
