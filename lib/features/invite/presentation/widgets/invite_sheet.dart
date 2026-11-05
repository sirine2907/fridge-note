import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pill_button.dart';
import '../cubit/invite_cubits.dart';

/// Share sheet with the invite link and a QR code.
class InviteSheet extends StatelessWidget {
  const InviteSheet({super.key, required this.listId, required this.listName});

  final String listId;
  final String listName;

  static Future<void> show(BuildContext context, {required String listId, required String listName}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => InviteSheet(listId: listId, listName: listName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InviteLinkCubit(sl())..create(listId),
      child: _InviteView(listName: listName),
    );
  }
}

class _InviteView extends StatelessWidget {
  const _InviteView({required this.listName});

  final String listName;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return BlocBuilder<InviteLinkCubit, InviteLinkState>(
      builder: (context, state) {
        final link = state.link;
        final code = context.read<InviteLinkCubit>().code;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Invite to $listName', style: text.headlineMedium?.copyWith(fontSize: 24), textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(
                  'Anyone with this link can see and edit the list.',
                  style: text.bodyMedium?.copyWith(color: c.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  width: 220,
                  height: 220,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: c.border),
                  ),
                  child: link == null
                      ? Center(
                          child: state.error == null
                              ? CircularProgressIndicator(color: c.primary)
                              : Text(state.error!, textAlign: TextAlign.center, style: text.bodySmall),
                        )
                      : QrImageView(
                          data: link,
                          padding: EdgeInsets.zero,
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: AppColors.ink),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.circle,
                            color: AppColors.violet,
                          ),
                        ),
                ),
                if (code != null) ...[
                  const SizedBox(height: 14),
                  Text('Code: $code', style: text.titleMedium?.copyWith(letterSpacing: 2)),
                ],
                const SizedBox(height: 16),
                Container(
                  height: 52,
                  padding: const EdgeInsets.only(left: 18, right: 4),
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link_rounded, color: c.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          link ?? 'Creating link...',
                          style: text.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy link',
                        icon: Icon(Icons.content_copy_rounded, color: c.primary, size: 20),
                        onPressed: link == null
                            ? null
                            : () async {
                                await Clipboard.setData(ClipboardData(text: link));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(content: Text('Link copied')));
                                }
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PillButton(
                  label: 'Share link',
                  icon: Icons.ios_share_rounded,
                  onPressed: link == null
                      ? null
                      : () => SharePlus.instance.share(ShareParams(
                            text: 'Join my list "$listName" on fridge-note: $link',
                            subject: 'fridge-note invite',
                          )),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
