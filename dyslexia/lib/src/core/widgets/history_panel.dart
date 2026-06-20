import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../api/api_helper.dart';
import '../api/feature_history_datasource.dart';

class HistoryPanel extends StatefulWidget {
  final String? feature;
  final ValueChanged<String> onSelectInput;
  final ValueChanged<FeatureHistoryItem> onSelectResult;

  const HistoryPanel({
    super.key,
    this.feature,
    required this.onSelectInput,
    required this.onSelectResult,
  });

  @override
  State<HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends State<HistoryPanel> {
  late final FeatureHistoryDatasource _ds;
  List<FeatureHistoryItem>? _items;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ds = FeatureHistoryDatasource(context.read<ApiHelper>());
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _ds.getHistory(feature: widget.feature);
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text('History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.refresh_rounded, size: 20), onPressed: _load),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items == null || _items!.isEmpty
                      ? const Center(child: Text('No history yet', style: TextStyle(color: Colors.black45)))
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _items!.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _HistoryTile(
                            item: _items![i],
                            onTap: () => widget.onSelectResult(_items![i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final FeatureHistoryItem item;
  final VoidCallback onTap;
  const _HistoryTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final preview = item.inputText.length > 80 ? '${item.inputText.substring(0, 80)}…' : item.inputText;
    final date = '${item.createdAt.month}/${item.createdAt.day} ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_rounded, size: 14, color: Colors.black45),
                  const SizedBox(width: 6),
                  Expanded(child: Text(preview, style: const TextStyle(fontSize: 12, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  Text(date, style: const TextStyle(fontSize: 10, color: Colors.black38)),
                ],
              ),
              if (item.outputText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(item.outputText.length > 80 ? '${item.outputText.substring(0, 80)}…' : item.outputText,
                    style: const TextStyle(fontSize: 11, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
