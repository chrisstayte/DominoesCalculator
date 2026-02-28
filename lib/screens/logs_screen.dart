import 'package:dominoes/providers/game_log_provider.dart';
import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:dominoes/widgets/game_log_detail_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nbt = NeoBrutalistTheme.of(context);
    final gameLogProvider = context.watch<GameLogProvider>();
    final logs = gameLogProvider.logs;
    final dateFormat = DateFormat('MMM d, yyyy  h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Transform(
          transform: Matrix4.skewX(-0.15),
          child: Container(
            color: nbt.headerColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'GAME_LOGS',
              style: GoogleFonts.bricolageGrotesque(
                color: nbt.headerTextColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        centerTitle: true,
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
          : ListView.builder(
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
                        border: Border.all(color: nbt.borderColor, width: 3),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }
}
