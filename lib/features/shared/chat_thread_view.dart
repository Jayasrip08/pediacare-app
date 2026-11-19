import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/health_repository.dart';
import '../../models/models.dart';
import '../../providers.dart';

/// Realtime chat between a parent and the clinic for one child.
class ChatThreadView extends ConsumerStatefulWidget {
  const ChatThreadView({super.key, required this.chatKey, required this.myRole});

  final ChatKey chatKey;
  final UserRole myRole;

  @override
  ConsumerState<ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends ConsumerState<ChatThreadView> {
  final _controller = TextEditingController();
  bool _sending = false;
  bool _marking = false;

  String get _role => widget.myRole.name; // 'parent' | 'doctor'

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markRead(List<Message> list) async {
    final hasUnread = list.any((m) => m.senderRole != _role && m.readAt == null);
    if (!hasUnread || _marking) return;
    _marking = true;
    try {
      await ref.read(chatRepositoryProvider).markRead(widget.chatKey, _role);
      ref.invalidate(chatThreadsProvider);
      ref.invalidate(doctorStatsProvider);
      ref.invalidate(unreadFromDoctorProvider(widget.chatKey.childId));
    } catch (_) {
      // Read receipts are best-effort.
    } finally {
      _marking = false;
    }
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(chatRepositoryProvider)
          .send(key: widget.chatKey, senderRole: _role, body: text);
      _controller.clear();
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _attach() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    final file = picked?.files.firstOrNull;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return;
    if (bytes.length > 10 * 1024 * 1024) {
      if (mounted) showToast(context, 'File is larger than 10 MB', error: true);
      return;
    }
    setState(() => _sending = true);
    try {
      final repo = ref.read(chatRepositoryProvider);
      final path = await repo.uploadAttachment(
          childId: widget.chatKey.childId, fileName: file.name, bytes: bytes);
      await repo.send(key: widget.chatKey, senderRole: _role, attachmentPath: path);
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final msgs = ref.watch(messagesProvider(widget.chatKey));
    ref.listen<AsyncValue<List<Message>>>(messagesProvider(widget.chatKey), (_, next) {
      next.whenData(_markRead);
    });

    return Column(
      children: [
        Expanded(
          child: msgs.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(
              message: errorMessage(e),
              onRetry: () => ref.invalidate(messagesProvider(widget.chatKey)),
            ),
            data: (list) {
              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Start the conversation',
                  message: widget.myRole == UserRole.parent
                      ? 'Share symptoms, photos or ask your doctor a question.'
                      : 'No messages with this family yet.',
                );
              }
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final k = list.length - 1 - i; // chronological index
                  final m = list[k];
                  final showDay =
                      k == 0 || dateOnly(list[k - 1].createdAt) != dateOnly(m.createdAt);
                  return Column(
                    children: [
                      if (showDay) _DayChip(m.createdAt),
                      _Bubble(message: m, mine: m.senderRole == _role),
                    ],
                  );
                },
              );
            },
          ),
        ),
        _Composer(
          controller: _controller,
          sending: _sending,
          onSend: _sendText,
          onAttach: _attach,
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip(this.date);

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: StatusPill(relativeDays(date) == 'Today' ? 'Today' : fmtDate(date)),
    );
  }
}

class _Bubble extends ConsumerWidget {
  const _Bubble({required this.message, required this.mine});

  final Message message;
  final bool mine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fg = mine ? Colors.white : AppColors.ink;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          color: mine ? AppColors.navy : Colors.white,
          border: mine ? null : Border.all(color: AppColors.line),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.attachmentPath != null)
              _Attachment(path: message.attachmentPath!, mine: mine),
            if (message.body != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(message.body!, style: AppText.body.copyWith(color: fg)),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(fmtTime(message.createdAt),
                    style: AppText.small
                        .copyWith(color: mine ? Colors.white60 : AppColors.muted, fontSize: 10.5)),
                if (mine) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all_rounded,
                      size: 14,
                      color: message.readAt != null ? AppColors.orange : Colors.white54),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Attachment extends ConsumerWidget {
  const _Attachment({required this.path, required this.mine});

  final String path;
  final bool mine;

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(signedUrlProvider(path));
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: url.when(
        loading: () => const SizedBox(
            height: 120, width: 180, child: Center(child: CircularProgressIndicator())),
        error: (_, __) => Text('Attachment unavailable',
            style: AppText.small.copyWith(color: mine ? Colors.white70 : AppColors.muted)),
        data: (u) => isImagePath(path)
            ? GestureDetector(
                onTap: () => _open(u),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(u, width: 200, height: 160, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                          width: 200, height: 80, child: Icon(Icons.broken_image_outlined))),
                ),
              )
            : InkWell(
                onTap: () => _open(u),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.picture_as_pdf_rounded,
                        color: mine ? Colors.white : AppColors.danger),
                    const SizedBox(width: 8),
                    Text('Open document',
                        style: AppText.bodyBold.copyWith(color: mine ? Colors.white : AppColors.ink)),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + MediaQuery.of(context).padding.bottom * 0),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: sending ? null : onAttach,
              icon: const Icon(Icons.attach_file_rounded, color: AppColors.muted),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message',
                  filled: true,
                  fillColor: AppColors.bg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Material(
              color: AppColors.orange,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: sending ? null : onSend,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
