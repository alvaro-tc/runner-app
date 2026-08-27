import 'package:camrun/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';

/// Distance, pace, duration and money rendering. Kept pure so it is unit
/// testable without a widget tree.
abstract final class Fmt {
  static const _kmPerMile = 1.609344;

  // ---------------------------------------------------------------- distance

  /// `12.5 km` / `7.8 mi`. [decimals] defaults to 1, which is what every
  /// screen in the app shows.
  static String distance(double km, {bool miles = false, int decimals = 1}) {
    final value = miles ? km / _kmPerMile : km;
    return '${value.toStringAsFixed(decimals)} ${miles ? 'mi' : 'km'}';
  }

  /// Bare number for the big display metrics, e.g. `12.5`.
  static String distanceValue(double km, {bool miles = false}) =>
      (miles ? km / _kmPerMile : km).toStringAsFixed(2);

  /// Ring label: `5K`, `14K`, `21K`.
  static String distanceShort(double km) => '${km.round()}K';

  // ------------------------------------------------------------------- pace

  /// Pace per km/mi as `5:53`. Values above 59:59 clamp so the label never
  /// blows up the layout.
  static String pace(Duration perKm, {bool miles = false}) {
    final seconds = miles
        ? (perKm.inSeconds * _kmPerMile).round()
        : perKm.inSeconds;
    if (seconds <= 0) return '--:--';
    final clamped = seconds > 3599 ? 3599 : seconds;
    final m = clamped ~/ 60;
    final s = clamped % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// `5:53/km`
  static String paceWithUnit(Duration perKm, {bool miles = false}) =>
      '${pace(perKm, miles: miles)}/${miles ? 'mi' : 'km'}';

  /// `6:10–6:30/km`
  static String paceRange(Duration min, Duration max, {bool miles = false}) =>
      '${pace(min, miles: miles)}–${paceWithUnit(max, miles: miles)}';

  // --------------------------------------------------------------- duration

  /// `04:32:16` — always includes hours, digits are tabular in the theme so
  /// the running clock does not jitter.
  static String clock(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${_two(h)}:${_two(m)}:${_two(s)}';
  }

  /// `4h 02m`, `45 min`, `52s` — the human-readable variant.
  static String durationShort(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${_two(d.inMinutes.remainder(60))}m';
    }
    if (d.inMinutes > 0) return '${d.inMinutes} min';
    return '${d.inSeconds}s';
  }

  /// `4h 02m – 4h 10m`
  static String durationRange(Duration min, Duration max) =>
      '${durationShort(min)} – ${durationShort(max)}';

  /// Countdown split into its parts: `34d`, `10h`, `24m`.
  static ({String days, String hours, String minutes, String seconds})
  countdown(Duration d) {
    final safe = d.isNegative ? Duration.zero : d;
    return (
      days: safe.inDays.toString(),
      hours: _two(safe.inHours.remainder(24)),
      minutes: _two(safe.inMinutes.remainder(60)),
      seconds: _two(safe.inSeconds.remainder(60)),
    );
  }

  /// `en 34 d` / `en 6 h` / `hoy` — lo pintan las tarjetas de carrera.
  ///
  /// El texto sale del ARB: aqui solo se decide **que** unidad toca.
  static String relativeShort(Duration d, AppLocalizations t) {
    if (d.isNegative) return t.relativeToday;
    if (d.inDays > 0) return t.relativeInDays(d.inDays);
    if (d.inHours > 0) return t.relativeInHours(d.inHours);
    return t.relativeInMinutes(d.inMinutes);
  }

  // ------------------------------------------------------------------- date

  static String dayMonth(DateTime d) => DateFormat('MMM d').format(d);
  static String weekdayDayMonth(DateTime d) =>
      DateFormat('EEE, d MMM').format(d);
  static String fullDate(DateTime d) => DateFormat('d MMMM y').format(d);
  static String monthYear(DateTime d) => DateFormat('MMMM y').format(d);
  static String weekdayShort(DateTime d) => DateFormat('EEE').format(d);

  /// Iniciales de lunes a domingo en el idioma activo (`L M X J V S D` en
  /// espanol, `M T W T F S S` en ingles). Las pinta el grafico semanal.
  static List<String> weekdayInitials() {
    final symbols = DateFormat.E().dateSymbols.NARROWWEEKDAYS;
    // `NARROWWEEKDAYS` empieza en domingo; la app cuenta semanas de lunes a
    // domingo, asi que se rota.
    return [...symbols.skip(1), symbols.first];
  }

  static String timeOfDay(DateTime d) => DateFormat('HH:mm').format(d);

  // ------------------------------------------------------------------ misc

  static String money(double amount, String currency) =>
      NumberFormat.simpleCurrency(name: currency).format(amount);

  static String speed(double kmh, {bool miles = false}) =>
      '${(miles ? kmh / _kmPerMile : kmh).toStringAsFixed(1)} ${miles ? 'mph' : 'km/h'}';

  static String elevation(double metres) => '${metres.round()} m';

  /// `#412 / 5,200`
  static String rank(int position, int total) =>
      '#${NumberFormat.decimalPattern().format(position)} / '
      '${NumberFormat.decimalPattern().format(total)}';

  static String _two(int v) => v.toString().padLeft(2, '0');
}
