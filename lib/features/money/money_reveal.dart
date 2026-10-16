import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The placeholder shown wherever a money amount is hidden. Kept for callers
/// that still reference it, but amounts are no longer masked.
const moneyMask = '***';

/// Money privacy was removed at the user's request: every amount is always
/// visible and no password is ever asked. [shows] is therefore always true.
class MoneyReveal {
  const MoneyReveal();

  bool shows(String id) => true;
}

class MoneyRevealNotifier extends Notifier<MoneyReveal> {
  @override
  MoneyReveal build() => const MoneyReveal();

  void revealAll() {}

  void revealOne(String id) {}

  /// No-op: nothing is hidden anymore.
  void reset() {}
}

final moneyRevealProvider = NotifierProvider<MoneyRevealNotifier, MoneyReveal>(
  MoneyRevealNotifier.new,
);

/// Amounts are always visible now — nothing to reveal, no password.
Future<void> revealMoneyFlow(
  BuildContext context,
  WidgetRef ref,
  String id,
) async {}

/// A money amount that is masked as [moneyMask] until revealed. [prefix] and
/// [suffix] (e.g. a label or trailing note) stay visible; only [amount] is
/// hidden. When [interactive] and masked, tapping runs [revealMoneyFlow];
/// otherwise the parent owns the tap (e.g. an edit/navigation row).
class MoneyText extends ConsumerWidget {
  const MoneyText({
    super.key,
    required this.id,
    required this.amount,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.textAlign,
    this.interactive = true,
  });

  final String id;
  final String amount;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final TextAlign? textAlign;
  final bool interactive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shown = ref.watch(moneyRevealProvider).shows(id);
    final text = Text(
      '$prefix${shown ? amount : moneyMask}$suffix',
      style: style,
      textAlign: textAlign,
    );
    if (!interactive || shown) return text;
    return InkWell(onTap: () => revealMoneyFlow(context, ref, id), child: text);
  }
}
