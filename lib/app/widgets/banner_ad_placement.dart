import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/banner_advertisement.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class BannerAdPlacement extends StatefulWidget {
  const BannerAdPlacement({
    super.key,
    required this.placement,
    this.carousel = false,
    this.margin = EdgeInsets.zero,
  });
  final String placement;
  final bool carousel;
  final EdgeInsetsGeometry margin;

  static final Set<_BannerAdPlacementState> _mountedPlacements = {};
  static Future<void> refreshAll() =>
      Future.wait(_mountedPlacements.map((state) => state._load()));

  @override
  State<BannerAdPlacement> createState() => _BannerAdPlacementState();
}

class _BannerAdPlacementState extends State<BannerAdPlacement>
    with WidgetsBindingObserver {
  List<BannerAdvertisement> _ads = const [];
  Timer? _timer;
  Timer? _refreshTimer;
  final PageController _pageController = PageController();
  int _page = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    BannerAdPlacement._mountedPlacements.add(this);
    WidgetsBinding.instance.addObserver(this);
    _load();
    _refreshTimer = Timer.periodic(const Duration(minutes: 50), (_) {
      if (mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _load();
      }
    });
  }

  @override
  void didUpdateWidget(covariant BannerAdPlacement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placement != widget.placement) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = Get.find<ApiService>();
      final rows = await api.bannerAds(placement: widget.placement);
      final unique = <String, BannerAdvertisement>{};
      for (final row in rows) {
        if (row is Map) {
          final ad = BannerAdvertisement.fromJson(
            Map<String, dynamic>.from(row),
          );
          if (ad.id.isNotEmpty &&
              ad.imageUrl.isNotEmpty &&
              ad.matchesPlacement(widget.placement)) {
            unique[ad.id] = ad;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _ads = unique.values.toList();
        _loading = false;
        _page = 0;
      });
      _startCarousel();
    } catch (_) {
      if (mounted) {
        setState(() {
          _ads = const [];
          _loading = false;
        });
      }
    }
  }

  void _startCarousel() {
    _timer?.cancel();
    if (!widget.carousel || _ads.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !TickerMode.valuesOf(context).enabled) return;
      _page = (_page + 1) % _ads.length;
      _pageController.animateToPage(
        _page,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _open(BannerAdvertisement ad) async {
    final value = ad.targetUrl;
    if (value == null) return;
    final uri = Uri.tryParse(value);
    if (uri == null) return;
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (value.startsWith('/') && Get.currentRoute != value) {
      Get.toNamed(value);
    }
  }

  bool _hasValidTarget(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    if (value.startsWith('/')) return true;
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  Widget _banner(BannerAdvertisement ad) {
    final hasText =
        ad.title != null ||
        ad.description != null ||
        (ad.buttonText != null && ad.targetUrl != null);
    final imageUrl = resolveBannerImageUrl(
      ad.imageUrl,
      Get.find<ApiService>().mediaApiBaseUrl,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: !_hasValidTarget(ad.targetUrl) ? null : () => _open(ad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: widget.carousel ? 16 / 7 : 16 / 6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.surfaceDark
                              : const Color(0xFFF1F5F3),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        if (kDebugMode) {
                          final status = error is NetworkImageLoadException
                              ? ' HTTP ${error.statusCode}'
                              : '';
                          debugPrint(
                            'Banner image ${ad.id} failed to load$status',
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    if (ad.isSponsored)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .92),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              'Sponsored',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (hasText) ...[
              if (ad.title != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    ad.title!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              if (ad.description != null)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    ad.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              if (ad.buttonText != null && ad.targetUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    ad.buttonText!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _ads.isEmpty) return const SizedBox.shrink();
    if (widget.carousel && _ads.length > 1) {
      return Padding(
        padding: widget.margin,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height:
                  (MediaQuery.sizeOf(context).width - 32).clamp(240.0, 1200.0) *
                  7 /
                  16,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _ads.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _banner(_ads[i]),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _ads.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: .3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: widget.margin,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _ads.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == _ads.length - 1 ? 0 : 12),
              child: _banner(_ads[i]),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    BannerAdPlacement._mountedPlacements.remove(this);
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _refreshTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
}
