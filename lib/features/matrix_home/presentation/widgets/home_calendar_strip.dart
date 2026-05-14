import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/home_calendar_store.dart';

/// Horizontal date strip — mirrors compass_v2_mobile/home_date_selector.dart.
/// Selected day: bold white text + white dot indicator below.
/// Tap → updates [HomeCalendarStore] which other home widgets listen to.
class HomeCalendarStrip extends StatelessWidget {
  const HomeCalendarStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HomeCalendarStore.instance,
      builder: (context, _) {
        final store = HomeCalendarStore.instance;
        final today = DateTime.now();
        // Show 5 days centred on today (yesterday → +3).
        final entries = List.generate(5, (i) {
          return today.add(Duration(days: i - 1));
        });

        return Container(
          color: AppColors.heroBackdrop,
          height: 72,
          width: double.infinity,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final date = entries[index];
              final isSelected = _sameDay(store.selectedDate, date);
              return GestureDetector(
                onTap: () => store.select(date),
                child: SizedBox(
                  width: 56,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _shortDayName(date.weekday),
                        style: GoogleFonts.roboto(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.64),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        date.day.toString().padLeft(2, '0'),
                        style: GoogleFonts.roboto(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.74),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _shortDayName(int w) {
    const names = {
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
      DateTime.saturday: 'Sat',
      DateTime.sunday: 'Sun',
    };
    return names[w] ?? '';
  }
}
