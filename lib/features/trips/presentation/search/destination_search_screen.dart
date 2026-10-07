import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../app/router.dart';
import '../../../../design_system/colors.dart';
import '../../../../design_system/spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models.dart';
import '../booking_controller.dart';

class DestinationSearchScreen extends ConsumerStatefulWidget {
  const DestinationSearchScreen({super.key});

  @override
  ConsumerState<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState
    extends ConsumerState<DestinationSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Place> _results = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final result =
        await ref.read(tripRepositoryProvider).savedAndRecentPlaces();
    if (!mounted) return;
    result.fold((places) => setState(() => _results = places), (_) {});
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      _loadSaved();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      setState(() => _loading = true);
      final result = await ref.read(tripRepositoryProvider).searchPlaces(value);
      if (!mounted) return;
      result.fold(
        (places) => setState(() {
          _results = places;
          _loading = false;
        }),
        (_) => setState(() => _loading = false),
      );
    });
  }

  void _select(Place place) {
    ref.read(bookingControllerProvider.notifier).setDestination(place);
    context.pushReplacement(Routes.confirm);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.whereTo),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(WesalSpacing.lg),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: l.searchDestination,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _PlaceTile(
                place: _results[i],
                onTap: () => _select(_results[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place, required this.onTap});
  final Place place;
  final VoidCallback onTap;

  IconData get _icon {
    switch (place.kind) {
      case PlaceKind.home:
        return Icons.home_outlined;
      case PlaceKind.work:
        return Icons.work_outline;
      case PlaceKind.saved:
        return Icons.star_outline;
      case PlaceKind.recent:
        return Icons.history;
      case PlaceKind.search:
        return Icons.location_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.surfaceContainerHighest,
        child: Icon(_icon, color: WesalColors.brand, size: 20),
      ),
      title: Text(place.title),
      subtitle: place.subtitle.isEmpty ? null : Text(place.subtitle),
      onTap: onTap,
    );
  }
}
