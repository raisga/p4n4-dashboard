import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/brand.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// "Contact support", when the brand names someone (brand.json `support`):
/// one way to get in touch opens at once, several are offered in a menu.
/// Nothing at all without one.
class ContactSupportButton extends StatelessWidget {
  const ContactSupportButton({super.key});

  static Future<void> _open(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.couldNotOpen('$uri'))));
    }
  }

  static (IconData, String) _describe(Uri uri) => switch (uri.scheme) {
    'mailto' => (Icons.mail_outline, uri.path),
    'tel' => (Icons.call_outlined, uri.path),
    _ => (Icons.open_in_new, uri.host),
  };

  @override
  Widget build(BuildContext context) {
    final contacts = BrandScope.maybeOf(context)?.support?.contacts ?? const [];
    if (contacts.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    final p4 = context.p4;
    const icon = Icon(Icons.support_agent, size: 18);
    if (contacts.length == 1) {
      return OutlinedButton.icon(
        onPressed: () => _open(context, contacts.single),
        icon: icon,
        label: Text(l.contactSupport),
      );
    }
    return MenuAnchor(
      menuChildren: [
        for (final uri in contacts)
          MenuItemButton(
            leadingIcon: Icon(_describe(uri).$1, size: 18, color: p4.muted),
            onPressed: () => _open(context, uri),
            child: Text(_describe(uri).$2),
          ),
      ],
      builder: (context, menu, _) => OutlinedButton.icon(
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
        icon: icon,
        label: Text(l.contactSupport),
      ),
    );
  }
}
