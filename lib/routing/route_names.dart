class RouteNames {
  RouteNames._();

  static const String login = '/login';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String clients = '/clients';
  static const String reports = '/reports';
  static const String more = '/more';

  // Lead routes
  static const String leads = '/leads';
  static const String leadDetail = '/leads/:leadId';
  static const String createLead = '/leads/new';
  static const String leadSearch = '/leads/search';

  // Profiling routes
  static const String profilingStart = '/profiling/:leadId/start';
  static const String profilingStatus = '/profiling/:id/status';
  static const String checkerQueue = '/profiling/queue';
  static const String profilingReview = '/profiling/:id/review';

  // Admin routes
  static const String adminLeads = '/admin/leads';
  static const String adminPool = '/admin/pool';
  static const String tlRequests = '/tl/requests';

  // Phase 1 additions
  static const String coverage = '/coverage';
  static const String clientDetail = '/clients/:clientId';
  static const String notifications = '/notifications';
  static const String ibLeadNew = '/ib-leads/new';
  static const String ibLeads = '/ib-leads';
  static const String ibLeadDetail = '/ib-leads/:ibLeadId';

  static String leadDetailPath(String leadId) => '/leads/$leadId';
  static String clientDetailPath(String clientId) => '/clients/$clientId';
  static String ibLeadDetailPath(String id) => '/ib-leads/$id';
}
