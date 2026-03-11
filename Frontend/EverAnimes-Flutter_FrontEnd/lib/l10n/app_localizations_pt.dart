// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'EverAnimes';

  @override
  String get back => 'Voltar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get create => 'Criar';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Excluir';

  @override
  String get remove => 'Remover';

  @override
  String get required => 'Obrigatório';

  @override
  String get invalidUrl => 'URL inválida';

  @override
  String get invalidEmail => 'Email inválido';

  @override
  String get email => 'Email';

  @override
  String get password => 'Senha';

  @override
  String get confirmPassword => 'Confirmar Senha';

  @override
  String get enterEmail => 'Informe o email.';

  @override
  String get enterPassword => 'Informe a senha.';

  @override
  String get passwordMinLength => 'Mínimo 6 caracteres';

  @override
  String get passwordMinLengthError =>
      'A senha deve ter pelo menos 6 caracteres.';

  @override
  String get passwordMismatch => 'As senhas não coincidem.';

  @override
  String get rateLimitError =>
      'Muitas tentativas. Aguarde um momento e tente novamente.';

  @override
  String get rateLimitErrorShort => 'Muitas requisições. Aguarde um momento.';

  @override
  String get unexpectedError => 'Erro inesperado. Tente novamente.';

  @override
  String get reload => 'Recarregar';

  @override
  String get login => 'Entrar';

  @override
  String get logout => 'Sair';

  @override
  String get tryAgain => 'Tentar novamente';

  @override
  String get url => 'URL';

  @override
  String get title => 'Título';

  @override
  String get site => 'Site';

  @override
  String get year => 'Ano';

  @override
  String get status => 'Status';

  @override
  String get add => 'Adicionar';

  @override
  String get filter => 'Filtrar';

  @override
  String get all => 'Todos';

  @override
  String get overview => 'Overview';

  @override
  String get episodes => 'Episódios';

  @override
  String get similar => 'Similares';

  @override
  String get links => 'Links';

  @override
  String get backToHome => 'Voltar para Home';

  @override
  String get pageNotFound => '404 – Página não encontrada';

  @override
  String get unexpectedErrorFallback => 'Ocorreu um erro inesperado';

  @override
  String get viewAll => 'Ver tudo';

  @override
  String get myList => 'Minha lista';

  @override
  String watchAnime(String title) {
    return 'Assistir $title';
  }

  @override
  String get loadingFeaturedContent => 'Carregando conteúdo em destaque';

  @override
  String get continueWatching => 'Continue Assistindo';

  @override
  String get headerBrowse => 'Explorar';

  @override
  String get headerMangas => 'Mangás';

  @override
  String get headerSearchHint => 'Buscar anime…';

  @override
  String get headerNotifications => 'Notificações';

  @override
  String get headerMyList => 'Minha Lista';

  @override
  String get headerProfile => 'Perfil';

  @override
  String get headerAdmin => 'Admin';

  @override
  String get homeCurrentSeason => 'Temporada Atual';

  @override
  String get homeFeaturedCover => 'Capa do anime em destaque';

  @override
  String get homeAddToList => 'Adicionar à lista';

  @override
  String get homeWatchNow => 'ASSISTIR AGORA';

  @override
  String get homeFeaturedBadge => 'EM DESTAQUE';

  @override
  String get homeDetails => 'Detalhes';

  @override
  String get homeSimilarDev => 'Busca de animes similares em desenvolvimento.';

  @override
  String get homeLoadingSynopsis => 'Carregando sinopse…';

  @override
  String get homeErrorSynopsis => 'Não foi possível carregar a sinopse.';

  @override
  String get homeEmptySynopsis => 'Sinopse não disponível.';

  @override
  String get homeLoadingEpisodes => 'Carregando episódios…';

  @override
  String get homeErrorEpisodes => 'Erro ao carregar episódios.';

  @override
  String get homeEmptyEpisodes => 'Nenhum episódio de streaming disponível.';

  @override
  String get homeLoadingLinks => 'Carregando links…';

  @override
  String get homeErrorLinks => 'Erro ao carregar links.';

  @override
  String get homeEmptyLinks => 'Nenhum link externo disponível.';

  @override
  String get homeCloseFeatured => 'Fechar destaque';

  @override
  String searchFilterByGenre(String genre) {
    return 'Filtrando por: $genre';
  }

  @override
  String searchFilterByYear(String year) {
    return 'Filtrando por ano: $year';
  }

  @override
  String get searchHintDefault => 'Ex: Naruto, Dragon Ball...';

  @override
  String get searchError => 'Erro ao buscar animes';

  @override
  String get searchSelectGenre => 'Selecione um gênero ou digite para buscar';

  @override
  String searchNoResults(String query) {
    return 'Nenhum resultado para \"$query\"';
  }

  @override
  String get searchGenres => 'Gêneros';

  @override
  String get searchGenresError => 'Erro ao carregar gêneros';

  @override
  String get searchSuggestionsError => 'Erro ao carregar sugestões';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginHeading => 'Entrar na sua conta';

  @override
  String get loginWrongCredentials => 'Email ou senha incorretos.';

  @override
  String get loginNoAccount => 'Não tem conta?';

  @override
  String get loginCreateAccount => 'Criar conta';

  @override
  String get registerTitle => 'Criar Conta';

  @override
  String get registerHeading => 'Criar nova conta';

  @override
  String get registerEmailExists => 'Este email já está cadastrado.';

  @override
  String get registerSuccess => 'Conta criada com sucesso! Entrando...';

  @override
  String get registerHasAccount => 'Já tem uma conta?';

  @override
  String get profileLogoutTitle => 'Sair da conta';

  @override
  String get profileLogoutConfirm => 'Tem certeza que deseja fazer logout?';

  @override
  String get profileUser => 'Usuário';

  @override
  String get profileAdmin => 'Administrador';

  @override
  String get profileRegularUser => 'Usuário comum';

  @override
  String get profileAccountInfo => 'Informações da Conta';

  @override
  String get profileAccessRole => 'Perfil de acesso';

  @override
  String get profileSessionStatus => 'Status da sessão';

  @override
  String get profileSessionActive => 'Ativa';

  @override
  String get profileActions => 'Ações';

  @override
  String get profileAdminPanel => 'Painel Admin';

  @override
  String get profileManageDesc => 'Gerenciar usuários e animes';

  @override
  String get profileHomePage => 'Página inicial';

  @override
  String get profileSearchAnimes => 'Buscar animes';

  @override
  String get detailsLoadError => 'Erro ao carregar detalhes';

  @override
  String get detailsEmptySynopsis => 'Sinopse não disponível.';

  @override
  String get detailsEmptyEpisodes => 'Nenhum episódio de streaming disponível.';

  @override
  String get detailsEmptyLinks => 'Nenhum link externo disponível.';

  @override
  String get detailsSimilarSoon => 'Títulos similares em breve.';

  @override
  String get playerLoadError => 'Erro ao carregar episódio';

  @override
  String get playerEmptyEpisodes => 'Nenhum episódio disponível';

  @override
  String get playerPrevEpisode => 'Episódio anterior';

  @override
  String playerEpisodeCount(String current, String total) {
    return 'Episódio $current de $total';
  }

  @override
  String get playerNextEpisode => 'Próximo episódio';

  @override
  String get genresLoadError => 'Erro ao carregar gêneros';

  @override
  String get genresEmpty => 'Nenhum gênero encontrado.';

  @override
  String get mangasTitle => 'Mangás';

  @override
  String get mangasInDevelopment => 'Em desenvolvimento';

  @override
  String get mangasDescription =>
      'Estamos preparando uma experiência incrível para leitura de mangás. Em breve estará disponível!';

  @override
  String mangasProgress(String progress) {
    return 'Progresso estimado: $progress%';
  }

  @override
  String get adminPanelTitle => 'Painel Admin';

  @override
  String get adminArea => 'Área Administrativa';

  @override
  String adminLoggedAs(String email) {
    return 'Logado como $email';
  }

  @override
  String get adminManagement => 'Gerenciamento';

  @override
  String get adminManageUsers => 'Gerenciar Usuários';

  @override
  String get adminManageUsersDesc => 'Criar, editar e remover usuários';

  @override
  String get adminManageAnimes => 'Gerenciar Animes';

  @override
  String get adminManageAnimesDesc => 'CRUD de animes locais';

  @override
  String get adminApiTest => 'API Explorer';

  @override
  String get adminApiTestDesc => 'Navegar e testar endpoints da API';

  @override
  String get adminNavigation => 'Navegação';

  @override
  String get adminHomePage => 'Página Inicial';

  @override
  String get adminMyProfile => 'Meu Perfil';

  @override
  String get adminAnimesNewAnime => 'Novo Anime';

  @override
  String get adminAnimesLoadError => 'Erro ao carregar animes';

  @override
  String get adminAnimesEmpty => 'Nenhum anime encontrado.';

  @override
  String get adminAnimesCreateTitle => 'Criar Anime';

  @override
  String get adminAnimesEditTitle => 'Editar Anime';

  @override
  String adminAnimesCreated(String date) {
    return 'Criado $date';
  }

  @override
  String get adminAnimesBasicData => 'Dados Básicos';

  @override
  String get adminAnimesTitleLabel => 'Título *';

  @override
  String get adminAnimesTitleRequired => 'Título é obrigatório';

  @override
  String get adminAnimesSynopsis => 'Sinopse';

  @override
  String get adminAnimesInvalidYear => 'Ano inválido';

  @override
  String get adminAnimesMinYear => 'Mín. 1900';

  @override
  String adminAnimesMaxYear(String year) {
    return 'Máx. $year';
  }

  @override
  String get adminAnimesScore => 'Score (0–10)';

  @override
  String get adminAnimesInvalid => 'Inválido';

  @override
  String get adminAnimesScoreRange => '0–10';

  @override
  String get adminAnimesCoverUrl => 'URL da capa';

  @override
  String get adminAnimesLocalDetails => 'Detalhes Locais';

  @override
  String get adminAnimesEpisodeCount => 'Nº Episódios';

  @override
  String get adminAnimesEpisodeRange => '0–5000';

  @override
  String get adminAnimesDuration => 'Duração (min)';

  @override
  String get adminAnimesDurationRange => '1–300';

  @override
  String get adminAnimesExternalLinks => 'Links Externos';

  @override
  String get adminAnimesStreamingEpisodes => 'Episódios Streaming';

  @override
  String get adminAnimesDeleteTitle => 'Excluir Anime';

  @override
  String get adminAnimesDeleteConfirm =>
      'Tem certeza que deseja excluir o anime?';

  @override
  String adminAnimesDeleteYear(String year) {
    return 'Ano: $year';
  }

  @override
  String get adminAnimesDeleteWarning => 'Esta ação não pode ser desfeita.';

  @override
  String get adminUsersNewUser => 'Novo Usuário';

  @override
  String get adminUsersLoadError => 'Erro ao carregar usuários';

  @override
  String get adminUsersEmpty => 'Nenhum usuário encontrado.';

  @override
  String get adminUsersCreateTitle => 'Criar Usuário';

  @override
  String get adminUsersEditTitle => 'Editar Usuário';

  @override
  String adminUsersCreatedAt(String date) {
    return 'Criado em $date';
  }

  @override
  String get adminUsersEmailRequired => 'Email é obrigatório';

  @override
  String get adminUsersNewPassword => 'Nova senha (deixe vazio para manter)';

  @override
  String get adminUsersPasswordRequired => 'Senha é obrigatória';

  @override
  String get adminUsersRole => 'Role';

  @override
  String get adminUsersDeleteTitle => 'Excluir Usuário';

  @override
  String get adminUsersDeleteConfirm =>
      'Tem certeza que deseja excluir o usuário?';

  @override
  String adminUsersDeleteRole(String role) {
    return 'Role: $role';
  }

  @override
  String get adminUsersDeleteWarning => 'Esta ação não pode ser desfeita.';

  @override
  String get apiTestTitle => 'API Explorer';

  @override
  String apiTestUnexpectedError(String error) {
    return 'Erro inesperado: $error';
  }

  @override
  String get apiTestRepeat => 'Atualizar';

  @override
  String get apiExplorerNoEndpoints => 'Nenhum endpoint encontrado';

  @override
  String get apiExplorerTryIt => 'Testar';

  @override
  String get apiExplorerSend => 'Enviar';

  @override
  String get apiExplorerResponse => 'Resposta';

  @override
  String get apiExplorerParams => 'Parâmetros';

  @override
  String get apiExplorerRequired => 'obrigatório';

  @override
  String get apiExplorerBody => 'Corpo da Requisição';

  @override
  String get accessDeniedTitle => 'Acesso Negado';

  @override
  String get accessDeniedMessage =>
      'Você não tem permissão para acessar esta página.\nEsta área é restrita a administradores.';

  @override
  String footerCopyright(String year) {
    return '© $year EverAnimes. Todos os direitos reservados.';
  }

  @override
  String get footerDescription =>
      'Sua plataforma de animes favorita.\nDescubra, explore e acompanhe milhares de títulos\ncom informações detalhadas de várias fontes.';

  @override
  String get footerGithub => 'GitHub';

  @override
  String get footerWebsite => 'Website';

  @override
  String get footerContact => 'Contato';

  @override
  String get footerNavigation => 'Navegação';

  @override
  String get footerHome => 'Início';

  @override
  String get footerSearch => 'Buscar';

  @override
  String get footerExploreGenres => 'Explorar Gêneros';

  @override
  String get footerCurrentSeason => 'Temporada Atual';

  @override
  String get footerResources => 'Recursos';

  @override
  String get footerApiAniList => 'API AniList';

  @override
  String get footerApiMal => 'API MyAnimeList';

  @override
  String get footerApiKitsu => 'API Kitsu';

  @override
  String get footerDocs => 'Documentação';

  @override
  String get footerAbout => 'Sobre';

  @override
  String get footerPortfolio => 'Projeto Portfolio';

  @override
  String get footerOpenSource => 'Código Aberto';

  @override
  String get footerTerms => 'Termos de Uso';

  @override
  String get footerPrivacy => 'Privacidade';

  @override
  String get addedToList => 'Adicionado à sua lista!';

  @override
  String get alreadyInList => 'Este anime já está na sua lista.';

  @override
  String get addToListError => 'Erro ao adicionar à lista. Tente novamente.';

  @override
  String get myListEmpty =>
      'Sua lista está vazia. Adicione animes para começar!';

  @override
  String get myListRemoveConfirm =>
      'Tem certeza que deseja remover este anime da sua lista?';

  @override
  String get myListRemoved => 'Removido da sua lista.';

  @override
  String get myListStatusWatching => 'Assistindo';

  @override
  String get myListStatusCompleted => 'Completo';

  @override
  String get myListStatusPlanToWatch => 'Planejo Assistir';

  @override
  String get myListStatusDropped => 'Abandonado';

  @override
  String get myListStatusOnHold => 'Em Pausa';

  @override
  String get myListEditorMode => 'Modo editor';

  @override
  String get myListExitEditor => 'Sair do editor';

  @override
  String get myListSortAZ => 'A → Z';

  @override
  String get myListSortZA => 'Z → A';

  @override
  String get myListSortYearDesc => 'Ano ↓';

  @override
  String get myListSortYearAsc => 'Ano ↑';

  @override
  String get myListSortDateAdded => 'Adicionados recentemente';

  @override
  String get myListSortDateUpdated => 'Atualizados recentemente';

  @override
  String get myListSelectAll => 'Selecionar tudo';

  @override
  String get myListDeselectAll => 'Desmarcar';

  @override
  String myListSelectedCount(int count) {
    return '$count selecionado(s)';
  }

  @override
  String get myListChangeStatus => 'Alterar status';

  @override
  String myListItemsUpdated(int count) {
    return '$count item(ns) atualizado(s)';
  }

  @override
  String get myListUpdated => 'Atualizado com sucesso';

  @override
  String get myListScore => 'Nota (0–10)';

  @override
  String get myListEpisodesWatched => 'Episódios assistidos';

  @override
  String get myListNotes => 'Notas';

  @override
  String apiExplorerEndpointCount(int count) {
    return '$count endpoints';
  }
}
