import 'package:flutter/material.dart';

import '../core/brand.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// Role picker shown until someone signs in.
///
/// A placeholder for real sign-in: once p4n4-api has JWT auth this becomes a
/// credentials form and the role comes from the token.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final brand = BrandScope.of(context);
    final session = SessionScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: DefaultTextStyle(
                      style: p4.mono(size: 30, color: p4.accent, weight: FontWeight.w700, spacing: -0.05),
                      child: const Wordmark(size: 30),
                    ),
                  ),
                  if (brand.tagline.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(brand.tagline, textAlign: TextAlign.center, style: p4.mono()),
                  ],
                  const SizedBox(height: 40),
                  SectionHeader(tag: 'sign in', title: const Text('Choose how to continue')),
                  const SizedBox(height: 16),
                  _RoleCard(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Administrator',
                    desc: 'Every service, client deployments, stack controls and connection settings.',
                    onTap: () => session.signIn(Role.admin),
                  ),
                  const SizedBox(height: 12),
                  _RoleCard(
                    icon: Icons.person_outline,
                    title: 'Client',
                    desc: 'System health at a glance, dashboards, camera and assistant.',
                    onTap: () => session.signIn(Role.client),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Role selection is a placeholder until ${brand.platform}-api supports authentication.',
                    textAlign: TextAlign.center,
                    style: p4.mono(size: 10, spacing: 0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.icon, required this.title, required this.desc, required this.onTap});

  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return Material(
      color: p4.bg2,
      shape: Border.all(color: p4.border),
      child: InkWell(
        onTap: onTap,
        hoverColor: p4.bg3,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: p4.accent, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: p4.display()),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: p4.display(size: 13, color: p4.muted, weight: FontWeight.w400, spacing: 0),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: p4.muted),
            ],
          ),
        ),
      ),
    );
  }
}
