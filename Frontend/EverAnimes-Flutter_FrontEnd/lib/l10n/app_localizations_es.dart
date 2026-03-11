// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'EverAnimes';

  @override
  String get back => 'Volver';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get create => 'Crear';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Eliminar';

  @override
  String get remove => 'Quitar';

  @override
  String get required => 'Obligatorio';

  @override
  String get invalidUrl => 'URL no válida';

  @override
  String get invalidEmail => 'Email no válido';

  @override
  String get email => 'Email';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmPassword => 'Confirmar Contraseña';

  @override
  String get enterEmail => 'Introduce tu email.';

  @override
  String get enterPassword => 'Introduce tu contraseña.';

  @override
  String get passwordMinLength => 'Mínimo 6 caracteres';

  @override
  String get passwordMinLengthError =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get passwordMismatch => 'Las contraseñas no coinciden.';

  @override
  String get rateLimitError =>
      'Demasiados intentos. Espera un momento e inténtalo de nuevo.';

  @override
  String get rateLimitErrorShort =>
      'Demasiadas solicitudes. Espera un momento.';

  @override
  String get unexpectedError => 'Error inesperado. Inténtalo de nuevo.';

  @override
  String get reload => 'Recargar';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get url => 'URL';

  @override
  String get title => 'Título';

  @override
  String get site => 'Sitio';

  @override
  String get year => 'Año';

  @override
  String get status => 'Estado';

  @override
  String get add => 'Añadir';

  @override
  String get filter => 'Filtrar';

  @override
  String get all => 'Todos';

  @override
  String get overview => 'Resumen';

  @override
  String get episodes => 'Episodios';

  @override
  String get similar => 'Similares';

  @override
  String get links => 'Enlaces';

  @override
  String get backToHome => 'Volver al Inicio';

  @override
  String get pageNotFound => '404 – Página no encontrada';

  @override
  String get unexpectedErrorFallback => 'Ocurrió un error inesperado';

  @override
  String get viewAll => 'Ver todo';

  @override
  String get myList => 'Mi lista';

  @override
  String watchAnime(String title) {
    return 'Ver $title';
  }

  @override
  String get loadingFeaturedContent => 'Cargando contenido destacado';

  @override
  String get continueWatching => 'Seguir Viendo';

  @override
  String get headerBrowse => 'Explorar';

  @override
  String get headerMangas => 'Mangas';

  @override
  String get headerSearchHint => 'Buscar anime…';

  @override
  String get headerNotifications => 'Notificaciones';

  @override
  String get headerMyList => 'Mi Lista';

  @override
  String get headerProfile => 'Perfil';

  @override
  String get headerAdmin => 'Admin';

  @override
  String get homeCurrentSeason => 'Temporada Actual';

  @override
  String get homeFeaturedCover => 'Portada del anime destacado';

  @override
  String get homeAddToList => 'Añadir a la lista';

  @override
  String get homeWatchNow => 'VER AHORA';

  @override
  String get homeFeaturedBadge => 'DESTACADO';

  @override
  String get homeDetails => 'Detalles';

  @override
  String get homeSimilarDev =>
      'La búsqueda de animes similares está en desarrollo.';

  @override
  String get homeLoadingSynopsis => 'Cargando sinopsis…';

  @override
  String get homeErrorSynopsis => 'No se pudo cargar la sinopsis.';

  @override
  String get homeEmptySynopsis => 'Sinopsis no disponible.';

  @override
  String get homeLoadingEpisodes => 'Cargando episodios…';

  @override
  String get homeErrorEpisodes => 'Error al cargar episodios.';

  @override
  String get homeEmptyEpisodes => 'No hay episodios de streaming disponibles.';

  @override
  String get homeLoadingLinks => 'Cargando enlaces…';

  @override
  String get homeErrorLinks => 'Error al cargar enlaces.';

  @override
  String get homeEmptyLinks => 'No hay enlaces externos disponibles.';

  @override
  String get homeCloseFeatured => 'Cerrar destacado';

  @override
  String searchFilterByGenre(String genre) {
    return 'Filtrando por: $genre';
  }

  @override
  String searchFilterByYear(String year) {
    return 'Filtrando por año: $year';
  }

  @override
  String get searchHintDefault => 'Ej: Naruto, Dragon Ball...';

  @override
  String get searchError => 'Error al buscar anime';

  @override
  String get searchSelectGenre => 'Selecciona un género o escribe para buscar';

  @override
  String searchNoResults(String query) {
    return 'Sin resultados para \"$query\"';
  }

  @override
  String get searchGenres => 'Géneros';

  @override
  String get searchGenresError => 'Error al cargar géneros';

  @override
  String get searchSuggestionsError => 'Error al cargar sugerencias';

  @override
  String get loginTitle => 'Iniciar Sesión';

  @override
  String get loginHeading => 'Accede a tu cuenta';

  @override
  String get loginWrongCredentials => 'Email o contraseña incorrectos.';

  @override
  String get loginNoAccount => '¿No tienes cuenta?';

  @override
  String get loginCreateAccount => 'Crear cuenta';

  @override
  String get registerTitle => 'Crear Cuenta';

  @override
  String get registerHeading => 'Crear una nueva cuenta';

  @override
  String get registerEmailExists => 'Este email ya está registrado.';

  @override
  String get registerSuccess => '¡Cuenta creada con éxito! Iniciando sesión...';

  @override
  String get registerHasAccount => '¿Ya tienes una cuenta?';

  @override
  String get profileLogoutTitle => 'Cerrar sesión';

  @override
  String get profileLogoutConfirm =>
      '¿Estás seguro de que deseas cerrar sesión?';

  @override
  String get profileUser => 'Usuario';

  @override
  String get profileAdmin => 'Administrador';

  @override
  String get profileRegularUser => 'Usuario común';

  @override
  String get profileAccountInfo => 'Información de la Cuenta';

  @override
  String get profileAccessRole => 'Rol de acceso';

  @override
  String get profileSessionStatus => 'Estado de la sesión';

  @override
  String get profileSessionActive => 'Activa';

  @override
  String get profileActions => 'Acciones';

  @override
  String get profileAdminPanel => 'Panel Admin';

  @override
  String get profileManageDesc => 'Gestionar usuarios y animes';

  @override
  String get profileHomePage => 'Página de inicio';

  @override
  String get profileSearchAnimes => 'Buscar anime';

  @override
  String get detailsLoadError => 'Error al cargar detalles';

  @override
  String get detailsEmptySynopsis => 'Sinopsis no disponible.';

  @override
  String get detailsEmptyEpisodes =>
      'No hay episodios de streaming disponibles.';

  @override
  String get detailsEmptyLinks => 'No hay enlaces externos disponibles.';

  @override
  String get detailsSimilarSoon => 'Títulos similares próximamente.';

  @override
  String get playerLoadError => 'Error al cargar episodio';

  @override
  String get playerEmptyEpisodes => 'No hay episodios disponibles';

  @override
  String get playerPrevEpisode => 'Episodio anterior';

  @override
  String playerEpisodeCount(String current, String total) {
    return 'Episodio $current de $total';
  }

  @override
  String get playerNextEpisode => 'Siguiente episodio';

  @override
  String get genresLoadError => 'Error al cargar géneros';

  @override
  String get genresEmpty => 'No se encontraron géneros.';

  @override
  String get mangasTitle => 'Mangas';

  @override
  String get mangasInDevelopment => 'En desarrollo';

  @override
  String get mangasDescription =>
      'Estamos preparando una experiencia increíble de lectura de mangas. ¡Pronto estará disponible!';

  @override
  String mangasProgress(String progress) {
    return 'Progreso estimado: $progress%';
  }

  @override
  String get adminPanelTitle => 'Panel Admin';

  @override
  String get adminArea => 'Área Administrativa';

  @override
  String adminLoggedAs(String email) {
    return 'Conectado como $email';
  }

  @override
  String get adminManagement => 'Gestión';

  @override
  String get adminManageUsers => 'Gestionar Usuarios';

  @override
  String get adminManageUsersDesc => 'Crear, editar y eliminar usuarios';

  @override
  String get adminManageAnimes => 'Gestionar Animes';

  @override
  String get adminManageAnimesDesc => 'CRUD de animes locales';

  @override
  String get adminApiTest => 'API Explorer';

  @override
  String get adminApiTestDesc => 'Navegar y probar endpoints de la API';

  @override
  String get adminNavigation => 'Navegación';

  @override
  String get adminHomePage => 'Página de Inicio';

  @override
  String get adminMyProfile => 'Mi Perfil';

  @override
  String get adminAnimesNewAnime => 'Nuevo Anime';

  @override
  String get adminAnimesLoadError => 'Error al cargar animes';

  @override
  String get adminAnimesEmpty => 'No se encontraron animes.';

  @override
  String get adminAnimesCreateTitle => 'Crear Anime';

  @override
  String get adminAnimesEditTitle => 'Editar Anime';

  @override
  String adminAnimesCreated(String date) {
    return 'Creado $date';
  }

  @override
  String get adminAnimesBasicData => 'Datos Básicos';

  @override
  String get adminAnimesTitleLabel => 'Título *';

  @override
  String get adminAnimesTitleRequired => 'El título es obligatorio';

  @override
  String get adminAnimesSynopsis => 'Sinopsis';

  @override
  String get adminAnimesInvalidYear => 'Año no válido';

  @override
  String get adminAnimesMinYear => 'Mín. 1900';

  @override
  String adminAnimesMaxYear(String year) {
    return 'Máx. $year';
  }

  @override
  String get adminAnimesScore => 'Puntuación (0–10)';

  @override
  String get adminAnimesInvalid => 'No válido';

  @override
  String get adminAnimesScoreRange => '0–10';

  @override
  String get adminAnimesCoverUrl => 'URL de portada';

  @override
  String get adminAnimesLocalDetails => 'Detalles Locales';

  @override
  String get adminAnimesEpisodeCount => 'Nº Episodios';

  @override
  String get adminAnimesEpisodeRange => '0–5000';

  @override
  String get adminAnimesDuration => 'Duración (min)';

  @override
  String get adminAnimesDurationRange => '1–300';

  @override
  String get adminAnimesExternalLinks => 'Enlaces Externos';

  @override
  String get adminAnimesStreamingEpisodes => 'Episodios Streaming';

  @override
  String get adminAnimesDeleteTitle => 'Eliminar Anime';

  @override
  String get adminAnimesDeleteConfirm =>
      '¿Estás seguro de que deseas eliminar este anime?';

  @override
  String adminAnimesDeleteYear(String year) {
    return 'Año: $year';
  }

  @override
  String get adminAnimesDeleteWarning => 'Esta acción no se puede deshacer.';

  @override
  String get adminUsersNewUser => 'Nuevo Usuario';

  @override
  String get adminUsersLoadError => 'Error al cargar usuarios';

  @override
  String get adminUsersEmpty => 'No se encontraron usuarios.';

  @override
  String get adminUsersCreateTitle => 'Crear Usuario';

  @override
  String get adminUsersEditTitle => 'Editar Usuario';

  @override
  String adminUsersCreatedAt(String date) {
    return 'Creado el $date';
  }

  @override
  String get adminUsersEmailRequired => 'El email es obligatorio';

  @override
  String get adminUsersNewPassword =>
      'Nueva contraseña (dejar vacío para mantener)';

  @override
  String get adminUsersPasswordRequired => 'La contraseña es obligatoria';

  @override
  String get adminUsersRole => 'Rol';

  @override
  String get adminUsersDeleteTitle => 'Eliminar Usuario';

  @override
  String get adminUsersDeleteConfirm =>
      '¿Estás seguro de que deseas eliminar este usuario?';

  @override
  String adminUsersDeleteRole(String role) {
    return 'Rol: $role';
  }

  @override
  String get adminUsersDeleteWarning => 'Esta acción no se puede deshacer.';

  @override
  String get apiTestTitle => 'API Explorer';

  @override
  String apiTestUnexpectedError(String error) {
    return 'Error inesperado: $error';
  }

  @override
  String get apiTestRepeat => 'Actualizar';

  @override
  String get apiExplorerNoEndpoints => 'No se encontraron endpoints';

  @override
  String get apiExplorerTryIt => 'Probar';

  @override
  String get apiExplorerSend => 'Enviar';

  @override
  String get apiExplorerResponse => 'Respuesta';

  @override
  String get apiExplorerParams => 'Parámetros';

  @override
  String get apiExplorerRequired => 'obligatorio';

  @override
  String get apiExplorerBody => 'Cuerpo de Solicitud';

  @override
  String get accessDeniedTitle => 'Acceso Denegado';

  @override
  String get accessDeniedMessage =>
      'No tienes permiso para acceder a esta página.\nEsta área está restringida a administradores.';

  @override
  String footerCopyright(String year) {
    return '© $year EverAnimes. Todos los derechos reservados.';
  }

  @override
  String get footerDescription =>
      'Tu plataforma de anime favorita.\nDescubre, explora y sigue miles de títulos\ncon información detallada de múltiples fuentes.';

  @override
  String get footerGithub => 'GitHub';

  @override
  String get footerWebsite => 'Sitio Web';

  @override
  String get footerContact => 'Contacto';

  @override
  String get footerNavigation => 'Navegación';

  @override
  String get footerHome => 'Inicio';

  @override
  String get footerSearch => 'Buscar';

  @override
  String get footerExploreGenres => 'Explorar Géneros';

  @override
  String get footerCurrentSeason => 'Temporada Actual';

  @override
  String get footerResources => 'Recursos';

  @override
  String get footerApiAniList => 'API AniList';

  @override
  String get footerApiMal => 'API MyAnimeList';

  @override
  String get footerApiKitsu => 'API Kitsu';

  @override
  String get footerDocs => 'Documentación';

  @override
  String get footerAbout => 'Acerca de';

  @override
  String get footerPortfolio => 'Proyecto Portfolio';

  @override
  String get footerOpenSource => 'Código Abierto';

  @override
  String get footerTerms => 'Términos de Uso';

  @override
  String get footerPrivacy => 'Privacidad';

  @override
  String get addedToList => '¡Agregado a tu lista!';

  @override
  String get alreadyInList => 'Este anime ya está en tu lista.';

  @override
  String get addToListError =>
      'Error al agregar a la lista. Inténtalo de nuevo.';

  @override
  String get myListEmpty => 'Tu lista está vacía. ¡Agrega animes para empezar!';

  @override
  String get myListRemoveConfirm =>
      '¿Estás seguro de que quieres eliminar este anime de tu lista?';

  @override
  String get myListRemoved => 'Eliminado de tu lista.';

  @override
  String get myListStatusWatching => 'Viendo';

  @override
  String get myListStatusCompleted => 'Completado';

  @override
  String get myListStatusPlanToWatch => 'Planeando Ver';

  @override
  String get myListStatusDropped => 'Abandonado';

  @override
  String get myListStatusOnHold => 'En Pausa';

  @override
  String get myListEditorMode => 'Modo editor';

  @override
  String get myListExitEditor => 'Salir del editor';

  @override
  String get myListSortAZ => 'A → Z';

  @override
  String get myListSortZA => 'Z → A';

  @override
  String get myListSortYearDesc => 'Año ↓';

  @override
  String get myListSortYearAsc => 'Año ↑';

  @override
  String get myListSortDateAdded => 'Añadidos recientemente';

  @override
  String get myListSortDateUpdated => 'Actualizados recientemente';

  @override
  String get myListSelectAll => 'Seleccionar todo';

  @override
  String get myListDeselectAll => 'Deseleccionar';

  @override
  String myListSelectedCount(int count) {
    return '$count seleccionado(s)';
  }

  @override
  String get myListChangeStatus => 'Cambiar estado';

  @override
  String myListItemsUpdated(int count) {
    return '$count elemento(s) actualizado(s)';
  }

  @override
  String get myListUpdated => 'Actualizado con éxito';

  @override
  String get myListScore => 'Puntuación (0–10)';

  @override
  String get myListEpisodesWatched => 'Episodios vistos';

  @override
  String get myListNotes => 'Notas';

  @override
  String apiExplorerEndpointCount(int count) {
    return '$count endpoints';
  }
}
