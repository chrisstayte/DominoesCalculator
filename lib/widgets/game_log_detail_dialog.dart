import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/models/game_log.dart';
import 'package:dominoes/providers/game_log_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GameLogDetailDialog extends StatelessWidget {
  const GameLogDetailDialog({super.key, required this.log});

  final GameLog log;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy  h:mm a');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 4),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(6, 6),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'GAME_LOG',
                      style: GoogleFonts.bricolageGrotesque(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            // Date and free point info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFormat.format(log.timestamp),
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'FREE POINT: ${log.freePointValue}',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            // Pip list
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: log.pips.length,
                itemBuilder: (context, index) {
                  final pipValue = log.pips[index];
                  final pip = DominoPips.fromInt(pipValue);
                  final displayValue =
                      pip == DominoPips.p0 ? log.freePointValue : pip.value;

                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.black,
                          width: index < log.pips.length - 1 ? 2 : 0,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${index + 1}.',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(2, 2),
                                blurRadius: 0,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: pip == DominoPips.p0
                              ? Center(
                                  child: Text(
                                    log.freePointValue.toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                )
                              : SvgPicture.asset(
                                  'assets/images/pips/${pip.readable}_black.svg',
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$displayValue pts',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Total and delete row
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.black, width: 2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'TOTAL: ${log.total}',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.read<GameLogProvider>().deleteLog(log.id);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 2),
                        color: const Color(0xFFFF4344),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'DELETE',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
