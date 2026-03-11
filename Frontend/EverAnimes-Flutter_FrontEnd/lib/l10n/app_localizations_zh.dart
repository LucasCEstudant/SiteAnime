// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'EverAnimes';

  @override
  String get back => '返回';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get create => '创建';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get remove => '移除';

  @override
  String get required => '必填';

  @override
  String get invalidUrl => '无效的URL';

  @override
  String get invalidEmail => '无效的邮箱';

  @override
  String get email => '邮箱';

  @override
  String get password => '密码';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get enterEmail => '请输入邮箱。';

  @override
  String get enterPassword => '请输入密码。';

  @override
  String get passwordMinLength => '至少6个字符';

  @override
  String get passwordMinLengthError => '密码至少需要6个字符。';

  @override
  String get passwordMismatch => '两次输入的密码不一致。';

  @override
  String get rateLimitError => '尝试次数过多。请稍等片刻后重试。';

  @override
  String get rateLimitErrorShort => '请求过多。请稍等片刻。';

  @override
  String get unexpectedError => '意外错误。请重试。';

  @override
  String get reload => '刷新';

  @override
  String get login => '登录';

  @override
  String get logout => '退出';

  @override
  String get tryAgain => '重试';

  @override
  String get url => 'URL';

  @override
  String get title => '标题';

  @override
  String get site => '网站';

  @override
  String get year => '年份';

  @override
  String get status => '状态';

  @override
  String get add => '添加';

  @override
  String get filter => '筛选';

  @override
  String get all => '全部';

  @override
  String get overview => '概览';

  @override
  String get episodes => '剧集';

  @override
  String get similar => '相似';

  @override
  String get links => '链接';

  @override
  String get backToHome => '返回首页';

  @override
  String get pageNotFound => '404 – 页面未找到';

  @override
  String get unexpectedErrorFallback => '发生了意外错误';

  @override
  String get viewAll => '查看全部';

  @override
  String get myList => '我的列表';

  @override
  String watchAnime(String title) {
    return '观看 $title';
  }

  @override
  String get loadingFeaturedContent => '正在加载推荐内容';

  @override
  String get continueWatching => '继续观看';

  @override
  String get headerBrowse => '浏览';

  @override
  String get headerMangas => '漫画';

  @override
  String get headerSearchHint => '搜索动漫…';

  @override
  String get headerNotifications => '通知';

  @override
  String get headerMyList => '我的列表';

  @override
  String get headerProfile => '个人资料';

  @override
  String get headerAdmin => '管理';

  @override
  String get homeCurrentSeason => '当季新番';

  @override
  String get homeFeaturedCover => '推荐动漫封面';

  @override
  String get homeAddToList => '添加到列表';

  @override
  String get homeWatchNow => '立即观看';

  @override
  String get homeFeaturedBadge => '推荐';

  @override
  String get homeDetails => '详情';

  @override
  String get homeSimilarDev => '相似动漫搜索正在开发中。';

  @override
  String get homeLoadingSynopsis => '正在加载简介…';

  @override
  String get homeErrorSynopsis => '无法加载简介。';

  @override
  String get homeEmptySynopsis => '暂无简介。';

  @override
  String get homeLoadingEpisodes => '正在加载剧集…';

  @override
  String get homeErrorEpisodes => '加载剧集出错。';

  @override
  String get homeEmptyEpisodes => '没有可用的流媒体剧集。';

  @override
  String get homeLoadingLinks => '正在加载链接…';

  @override
  String get homeErrorLinks => '加载链接出错。';

  @override
  String get homeEmptyLinks => '没有可用的外部链接。';

  @override
  String get homeCloseFeatured => '关闭推荐';

  @override
  String searchFilterByGenre(String genre) {
    return '按类型筛选：$genre';
  }

  @override
  String searchFilterByYear(String year) {
    return '按年份筛选：$year';
  }

  @override
  String get searchHintDefault => '例如：火影忍者、龙珠...';

  @override
  String get searchError => '搜索动漫出错';

  @override
  String get searchSelectGenre => '选择类型或输入搜索';

  @override
  String searchNoResults(String query) {
    return '未找到 \"$query\" 的结果';
  }

  @override
  String get searchGenres => '类型';

  @override
  String get searchGenresError => '加载类型出错';

  @override
  String get searchSuggestionsError => '加载建议出错';

  @override
  String get loginTitle => '登录';

  @override
  String get loginHeading => '登录您的账户';

  @override
  String get loginWrongCredentials => '邮箱或密码错误。';

  @override
  String get loginNoAccount => '还没有账户？';

  @override
  String get loginCreateAccount => '创建账户';

  @override
  String get registerTitle => '创建账户';

  @override
  String get registerHeading => '创建新账户';

  @override
  String get registerEmailExists => '此邮箱已被注册。';

  @override
  String get registerSuccess => '账户创建成功！正在登录...';

  @override
  String get registerHasAccount => '已有账户？';

  @override
  String get profileLogoutTitle => '退出登录';

  @override
  String get profileLogoutConfirm => '确定要退出登录吗？';

  @override
  String get profileUser => '用户';

  @override
  String get profileAdmin => '管理员';

  @override
  String get profileRegularUser => '普通用户';

  @override
  String get profileAccountInfo => '账户信息';

  @override
  String get profileAccessRole => '访问角色';

  @override
  String get profileSessionStatus => '会话状态';

  @override
  String get profileSessionActive => '活跃';

  @override
  String get profileActions => '操作';

  @override
  String get profileAdminPanel => '管理面板';

  @override
  String get profileManageDesc => '管理用户和动漫';

  @override
  String get profileHomePage => '首页';

  @override
  String get profileSearchAnimes => '搜索动漫';

  @override
  String get detailsLoadError => '加载详情出错';

  @override
  String get detailsEmptySynopsis => '暂无简介。';

  @override
  String get detailsEmptyEpisodes => '没有可用的流媒体剧集。';

  @override
  String get detailsEmptyLinks => '没有可用的外部链接。';

  @override
  String get detailsSimilarSoon => '相似作品即将推出。';

  @override
  String get playerLoadError => '加载剧集出错';

  @override
  String get playerEmptyEpisodes => '没有可用的剧集';

  @override
  String get playerPrevEpisode => '上一集';

  @override
  String playerEpisodeCount(String current, String total) {
    return '第 $current 集 / 共 $total 集';
  }

  @override
  String get playerNextEpisode => '下一集';

  @override
  String get genresLoadError => '加载类型出错';

  @override
  String get genresEmpty => '未找到类型。';

  @override
  String get mangasTitle => '漫画';

  @override
  String get mangasInDevelopment => '开发中';

  @override
  String get mangasDescription => '我们正在准备精彩的漫画阅读体验。敬请期待！';

  @override
  String mangasProgress(String progress) {
    return '预计进度：$progress%';
  }

  @override
  String get adminPanelTitle => '管理面板';

  @override
  String get adminArea => '管理区域';

  @override
  String adminLoggedAs(String email) {
    return '已登录为 $email';
  }

  @override
  String get adminManagement => '管理';

  @override
  String get adminManageUsers => '管理用户';

  @override
  String get adminManageUsersDesc => '创建、编辑和删除用户';

  @override
  String get adminManageAnimes => '管理动漫';

  @override
  String get adminManageAnimesDesc => '本地动漫增删改查';

  @override
  String get adminApiTest => 'API 浏览器';

  @override
  String get adminApiTestDesc => '浏览和测试API端点';

  @override
  String get adminNavigation => '导航';

  @override
  String get adminHomePage => '首页';

  @override
  String get adminMyProfile => '我的资料';

  @override
  String get adminAnimesNewAnime => '新建动漫';

  @override
  String get adminAnimesLoadError => '加载动漫出错';

  @override
  String get adminAnimesEmpty => '未找到动漫。';

  @override
  String get adminAnimesCreateTitle => '创建动漫';

  @override
  String get adminAnimesEditTitle => '编辑动漫';

  @override
  String adminAnimesCreated(String date) {
    return '创建于 $date';
  }

  @override
  String get adminAnimesBasicData => '基本信息';

  @override
  String get adminAnimesTitleLabel => '标题 *';

  @override
  String get adminAnimesTitleRequired => '标题为必填项';

  @override
  String get adminAnimesSynopsis => '简介';

  @override
  String get adminAnimesInvalidYear => '年份无效';

  @override
  String get adminAnimesMinYear => '最小 1900';

  @override
  String adminAnimesMaxYear(String year) {
    return '最大 $year';
  }

  @override
  String get adminAnimesScore => '评分（0–10）';

  @override
  String get adminAnimesInvalid => '无效';

  @override
  String get adminAnimesScoreRange => '0–10';

  @override
  String get adminAnimesCoverUrl => '封面URL';

  @override
  String get adminAnimesLocalDetails => '本地详情';

  @override
  String get adminAnimesEpisodeCount => '集数';

  @override
  String get adminAnimesEpisodeRange => '0–5000';

  @override
  String get adminAnimesDuration => '时长（分钟）';

  @override
  String get adminAnimesDurationRange => '1–300';

  @override
  String get adminAnimesExternalLinks => '外部链接';

  @override
  String get adminAnimesStreamingEpisodes => '流媒体剧集';

  @override
  String get adminAnimesDeleteTitle => '删除动漫';

  @override
  String get adminAnimesDeleteConfirm => '确定要删除此动漫吗？';

  @override
  String adminAnimesDeleteYear(String year) {
    return '年份：$year';
  }

  @override
  String get adminAnimesDeleteWarning => '此操作无法撤销。';

  @override
  String get adminUsersNewUser => '新建用户';

  @override
  String get adminUsersLoadError => '加载用户出错';

  @override
  String get adminUsersEmpty => '未找到用户。';

  @override
  String get adminUsersCreateTitle => '创建用户';

  @override
  String get adminUsersEditTitle => '编辑用户';

  @override
  String adminUsersCreatedAt(String date) {
    return '创建于 $date';
  }

  @override
  String get adminUsersEmailRequired => '邮箱为必填项';

  @override
  String get adminUsersNewPassword => '新密码（留空保持不变）';

  @override
  String get adminUsersPasswordRequired => '密码为必填项';

  @override
  String get adminUsersRole => '角色';

  @override
  String get adminUsersDeleteTitle => '删除用户';

  @override
  String get adminUsersDeleteConfirm => '确定要删除此用户吗？';

  @override
  String adminUsersDeleteRole(String role) {
    return '角色：$role';
  }

  @override
  String get adminUsersDeleteWarning => '此操作无法撤销。';

  @override
  String get apiTestTitle => 'API 浏览器';

  @override
  String apiTestUnexpectedError(String error) {
    return '意外错误：$error';
  }

  @override
  String get apiTestRepeat => '刷新';

  @override
  String get apiExplorerNoEndpoints => '未找到端点';

  @override
  String get apiExplorerTryIt => '测试';

  @override
  String get apiExplorerSend => '发送';

  @override
  String get apiExplorerResponse => '响应';

  @override
  String get apiExplorerParams => '参数';

  @override
  String get apiExplorerRequired => '必填';

  @override
  String get apiExplorerBody => '请求体';

  @override
  String get accessDeniedTitle => '访问被拒绝';

  @override
  String get accessDeniedMessage => '您没有权限访问此页面。\n此区域仅限管理员访问。';

  @override
  String footerCopyright(String year) {
    return '© $year EverAnimes。保留所有权利。';
  }

  @override
  String get footerDescription => '您最喜爱的动漫平台。\n发现、探索和追踪数千部作品\n来自多个来源的详细信息。';

  @override
  String get footerGithub => 'GitHub';

  @override
  String get footerWebsite => '网站';

  @override
  String get footerContact => '联系我们';

  @override
  String get footerNavigation => '导航';

  @override
  String get footerHome => '首页';

  @override
  String get footerSearch => '搜索';

  @override
  String get footerExploreGenres => '浏览类型';

  @override
  String get footerCurrentSeason => '当季新番';

  @override
  String get footerResources => '资源';

  @override
  String get footerApiAniList => 'API AniList';

  @override
  String get footerApiMal => 'API MyAnimeList';

  @override
  String get footerApiKitsu => 'API Kitsu';

  @override
  String get footerDocs => '文档';

  @override
  String get footerAbout => '关于';

  @override
  String get footerPortfolio => '作品集项目';

  @override
  String get footerOpenSource => '开源';

  @override
  String get footerTerms => '使用条款';

  @override
  String get footerPrivacy => '隐私政策';

  @override
  String get addedToList => '已添加到你的列表！';

  @override
  String get alreadyInList => '这部动漫已在你的列表中。';

  @override
  String get addToListError => '添加到列表失败。请重试。';

  @override
  String get myListEmpty => '你的列表是空的。添加动漫开始吧！';

  @override
  String get myListRemoveConfirm => '你确定要从列表中删除这部动漫吗？';

  @override
  String get myListRemoved => '已从列表中删除。';

  @override
  String get myListStatusWatching => '在看';

  @override
  String get myListStatusCompleted => '已完成';

  @override
  String get myListStatusPlanToWatch => '计划观看';

  @override
  String get myListStatusDropped => '已弃坑';

  @override
  String get myListStatusOnHold => '暂停';

  @override
  String get myListEditorMode => '编辑模式';

  @override
  String get myListExitEditor => '退出编辑';

  @override
  String get myListSortAZ => 'A → Z';

  @override
  String get myListSortZA => 'Z → A';

  @override
  String get myListSortYearDesc => '年份 ↓';

  @override
  String get myListSortYearAsc => '年份 ↑';

  @override
  String get myListSortDateAdded => '最近添加';

  @override
  String get myListSortDateUpdated => '最近更新';

  @override
  String get myListSelectAll => '全选';

  @override
  String get myListDeselectAll => '取消选择';

  @override
  String myListSelectedCount(int count) {
    return '已选 $count 项';
  }

  @override
  String get myListChangeStatus => '更改状态';

  @override
  String myListItemsUpdated(int count) {
    return '已更新 $count 项';
  }

  @override
  String get myListUpdated => '更新成功';

  @override
  String get myListScore => '评分 (0–10)';

  @override
  String get myListEpisodesWatched => '已看集数';

  @override
  String get myListNotes => '备注';

  @override
  String apiExplorerEndpointCount(int count) {
    return '$count 个端点';
  }
}
