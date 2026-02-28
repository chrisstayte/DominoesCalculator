import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/providers/calculator_provider.dart';
import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PipHistoryDialog extends StatelessWidget {
  const PipHistoryDialog({super.key, required this.freePointValue});

  final int freePointValue;

  @override
  Widget build(BuildContext context) {
    final nbt = NeoBrutalistTheme.of(context);
    final calculator = context.watch<CalculatorProvider>();
    final pips = calculator.selectedPips;

    return Dialog(
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'PIP_HISTORY',
                      style: GoogleFonts.bricolageGrotesque(
                        color: nbt.headerTextColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.close,
                      color: nbt.headerTextColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            if (pips.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Text(
                  'NO PIPS YET',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: nbt.secondaryTextColor,
                    letterSpacing: 1,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pips.length,
                  itemBuilder: (context, index) {
                    final pip = pips[index];
                    final displayValue =
                        pip == DominoPips.p0 ? freePointValue : pip.value;

                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: nbt.borderColor,
                            width: index < pips.length - 1 ? 2 : 0,
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
                                color: nbt.bodyTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: nbt.cardColor,
                              border:
                                  Border.all(color: nbt.borderColor, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: nbt.shadowColor,
                                  offset: const Offset(2, 2),
                                  blurRadius: 0,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(4),
                            child: pip == DominoPips.p0
                                ? Center(
                                    child: Text(
                                      freePointValue.toString(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: nbt.bodyTextColor,
                                      ),
                                    ),
                                  )
                                : SvgPicture.asset(
                                    'assets/images/pips/${pip.readable}_black.svg',
                                    colorFilter: ColorFilter.mode(nbt.bodyTextColor, BlendMode.srcIn),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '$displayValue pts',
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: nbt.bodyTextColor,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => calculator.removeAt(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: nbt.borderColor, width: 2),
                                color: nbt.accentRed,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 18,
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
          ],
        ),
      ),
    );
  }
}
