// =============================================================================
// FILE: lib/shared/widgets/mobile_infinite_scroll.dart
// PURPOSE: Mobile list with scroll-to-load-more (replaces pagination footer).
// =============================================================================

import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Scrollable list for narrow layouts: loads more when user nears the bottom.
///
/// Use on **mobile** (`!isWide`) instead of [ListPaginationBar]. Desktop tables
/// should keep pagination or [ListTableView] with `hasMore`/`onLoadMore`.
class MobileInfiniteScrollList extends StatefulWidget {
  const MobileInfiniteScrollList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    this.padding = const EdgeInsets.only(bottom: 8),
    this.scrollController,
    this.loadingLabel = 'Loading more…',
    this.showSkeletonFooter = true,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final bool hasMore;
  final bool isLoadingMore;
  final Future<void> Function() onLoadMore;
  final EdgeInsetsGeometry padding;
  final ScrollController? scrollController;
  final String loadingLabel;
  /// When true, shows placeholder bars above the spinner while loading more.
  final bool showSkeletonFooter;

  @override
  State<MobileInfiniteScrollList> createState() =>
      _MobileInfiniteScrollListState();
}

class _MobileInfiniteScrollListState extends State<MobileInfiniteScrollList> {
  late final ScrollController _controller;
  bool _ownController = false;
  bool _loadScheduled = false;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _controller = widget.scrollController!;
    } else {
      _controller = ScrollController();
      _ownController = true;
    }
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    if (_ownController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || widget.isLoadingMore || _loadScheduled) return;
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadScheduled = true;
      widget.onLoadMore().whenComplete(() {
        if (mounted) {
          setState(() => _loadScheduled = false);
        } else {
          _loadScheduled = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final footerCount =
        (widget.hasMore && widget.isLoadingMore) ? 1 : 0;
    final itemCount = widget.itemCount + footerCount;

    return ListView.builder(
      controller: _controller,
      padding: widget.padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= widget.itemCount) {
          return _LoadingMoreFooter(
            label: widget.loadingLabel,
            showSkeleton: widget.showSkeletonFooter,
          );
        }
        return widget.itemBuilder(context, index);
      },
    );
  }
}

class _LoadingMoreFooter extends StatelessWidget {
  const _LoadingMoreFooter({
    required this.label,
    required this.showSkeleton,
  });

  final String label;
  final bool showSkeleton;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      child: Column(
        children: [
          if (showSkeleton) ...[
            _skeletonLine(cs),
            const SizedBox(height: 8),
            _skeletonLine(cs),
            const SizedBox(height: 8),
            _skeletonLine(cs, widthFactor: 0.65),
            const SizedBox(height: 16),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonLine(ColorScheme cs, {double widthFactor = 1}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: AppRadius.brLg,
        ),
      ),
    );
  }
}
