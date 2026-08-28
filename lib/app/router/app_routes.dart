/// Route paths and names in one place — no string literals in the widgets.
abstract final class Routes {
  static const onboarding = '/onboarding';
  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  /// Puerta obligatoria para quien entro con una contrasena que no eligio
  /// (alta desde la web: usuario CI, contrasena CI).
  static const changePassword = '/change-password';

  static const home = '/home';
  static const marathonDetail = '/home/marathon/:id';
  static const marathonRegister = '/home/marathon/:id/register';

  static const train = '/train';
  static const trainSetup = '/train/setup';
  static const trainSession = '/train/session';
  static const trainSummary = '/train/summary/:id';
  static const trainHistory = '/train/history/:id';

  static const races = '/races';
  static const raceDetail = '/races/:id';
  static const raceStart = '/races/:id/start';

  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const profileSettings = '/profile/settings';
  static const profileAppearance = '/profile/appearance';
  static const profileLanguage = '/profile/language';
  static const profileShoes = '/profile/shoes';
  static const profileHealth = '/profile/health';
  static const profileDeleteAccount = '/profile/delete-account';

  /// El panel. Solo para `admin`: el guard manda ahi a quien lo sea y saca de
  /// ahi a quien no.
  static const admin = '/admin';
  static const adminMarathons = '/admin/marathons';
  static const adminMarathonNew = '/admin/marathons/new';
  static const adminMarathonEdit = '/admin/marathons/:id';
  static const adminUsers = '/admin/users';
  static const adminProfile = '/admin/profile';

  static const showcase = '/dev/showcase';

  static String marathonDetailOf(String id) => '/home/marathon/$id';
  static String marathonRegisterOf(String id) => '/home/marathon/$id/register';
  static String trainSummaryOf(String id) => '/train/summary/$id';
  static String trainHistoryOf(String id) => '/train/history/$id';
  static String raceDetailOf(String id) => '/races/$id';
  static String raceStartOf(String id) => '/races/$id/start';
  static String adminMarathonEditOf(String id) => '/admin/marathons/$id';
}
