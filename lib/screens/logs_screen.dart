import 'package:dominoes/providers/game_log_provider.dart';
import 'package:dominoes/providers/local_settings_provider.dart';
import 'package:dominoes/services/sfx_service.dart';
import 'package:dominoes/services/vibration_service.dart';
import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:dominoes/widgets/game_log_detail_dialog.dart';
import 'package:dominoes/widgets/skewed_header.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  void _showClearAllDialog(BuildContext context, NeoBrutalistTheme nbt) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Container(
          decoration: BoxDecoration(
            color: nbt.cardColor,
            border: Border.all(color: nbt.borderColor, width: 4),
            boxShadow: [
              BoxShadow(
                color: nbt.shadowColor,
                offset: const Offset(6, 6),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                color: nbt.headerColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  'CLEAR_ALL_LOGS',
                  style: GoogleFonts.bricolageGrotesque(
                    color: nbt.headerTextColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Are you sure you want to delete all game logs? This action cannot be undone.',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: nbt.bodyTextColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(_).pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: nbt.borderColor,
                              width: 2,
                            ),
                            color: nbt.cardColor,
                          ),
                          child: Center(
                            child: Text(
                              'CANCEL',
                              style: GoogleFonts.bricolageGrotesque(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 1,
                                color: nbt.bodyTextColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          context.read<SfxService>().playClear();
                          context.read<VibrationService>().heavy();
                          context.read<GameLogProvider>().clearAllLogs();
                          Navigator.of(_).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: nbt.borderColor,
                              width: 2,
                            ),
                            color: nbt.accentRed,
                            boxShadow: [
                              BoxShadow(
                                color: nbt.shadowColor,
                                offset: const Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'DELETE ALL',
                              style: GoogleFonts.bricolageGrotesque(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 1,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nbt = NeoBrutalistTheme.of(context);
    final gameLogProvider = context.watch<GameLogProvider>();
    final logs = gameLogProvider.logs;
    final dateFormat = DateFormat('MMM d, yyyy  h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const SkewedHeader(label: 'GAME_LOGS'),
        centerTitle: true,
        actions: [
          if (logs.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.delete_sweep_outlined,
                color: nbt.iconColor,
              ),
              onPressed: () => _showClearAllDialog(context, nbt),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(color: nbt.borderColor, height: 3),
        ),
      ),
      body: logs.isEmpty
          ? Center(
              child: Text(
                'NO LOGS YET',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: nbt.secondaryTextColor,
                  letterSpacing: 1,
                ),
              ),
            )
          : Column(
              children: [
                // Statistics summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: context
                        .watch<LocalSettingsProvider>()
                        .localSettings
                        .appAccentColor
                        .color,
                    border: Border(
                      bottom: BorderSide(color: nbt.borderColor, width: 3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(
                        label: 'GAMES',
                        value: '${gameLogProvider.totalGames}',
                      ),
                      _StatItem(
                        label: 'HIGH',
                        value: '${gameLogProvider.highScore}',
                      ),
                      _StatItem(
                        label: 'AVG',
                        value: gameLogProvider.averageScore
                            .toStringAsFixed(0),
                      ),
                    ],
                  ),
                ),
                // Log list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => ChangeNotifierProvider.value(
                                value: gameLogProvider,
                                child: GameLogDetailDialog(log: log),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: nbt.cardColor,
                              border:
                                  Border.all(color: nbt.borderColor, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: nbt.shadowColor,
                                  offset: const Offset(4, 4),
                                  blurRadius: 0,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dateFormat.format(log.timestamp),
                                        style: GoogleFonts.bricolageGrotesque(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: nbt.bodyTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${log.pips.length} pips',
                                        style: GoogleFonts.bricolageGrotesque(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: nbt.secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${log.total}',
                                  style: GoogleFonts.bricolageGrotesque(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: nbt.bodyTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
