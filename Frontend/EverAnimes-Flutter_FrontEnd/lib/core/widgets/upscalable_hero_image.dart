import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/image_upscale_service.dart';
import '../utils/proxied_image.dart';
import '../../features/auth/domain/auth_state_provider.dart';

/// A large hero/banner image that:
/// 1. Immediately shows the original image via [ProxiedImage].
/// 2. If the user is authenticated, requests an upscaled version
///    from `/api/images/upscale` in the background.
/// 3. Once the upscaled bytes arrive, cross-fades to the high-res version.
///
/// Use this ONLY for large display images (hero banners, detail backgrounds).
/// Small thumbnails should just use [ProxiedImage].
class UpscalableHeroImage extends ConsumerStatefulWidget {
  const UpscalableHeroImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.errorBuilder,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final String? semanticLabel;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  ConsumerState<UpscalableHeroImage> createState() =>
      _UpscalableHeroImageState();
}

class _UpscalableHeroImageState extends ConsumerState<UpscalableHeroImage> {
  Uint8List? _upscaledBytes;
  bool _loading = false;
  bool _attempted = false;

  @override
  void initState() {
    super.initState();
    _tryUpscale();
  }

  @override
  void didUpdateWidget(UpscalableHeroImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _upscaledBytes = null;
      _loading = false;
      _attempted = false;
      _tryUpscale();
    }
  }

  void _tryUpscale() {
    if (_attempted) return;
    _attempted = true;

    final isAuth = ref.read(authStateProvider).isAuthenticated;
    if (!isAuth) return;

    final service = ref.read(imageUpscaleServiceProvider);

    // Check cache first.
    final cached = service.getCached(widget.imageUrl);
    if (cached != null) {
      _upscaledBytes = cached;
      return;
    }

    _loading = true;

    // Fire and forget — update UI when result arrives.
    service.upscale(widget.imageUrl).then((bytes) {
      if (!mounted) return;
      setState(() {
        _upscaledBytes = bytes;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // If we have upscaled bytes, show them.
    if (_upscaledBytes != null) {
      return Stack(
        fit: StackFit.passthrough,
        children: [
          Image.memory(
            _upscaledBytes!,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
            alignment: widget.alignment,
            semanticLabel: widget.semanticLabel,
            errorBuilder: widget.errorBuilder,
          ),
          // Subtle loading badge fades out when done.
        ],
      );
    }

    // Show original via proxy (with optional tiny loading indicator).
    return Stack(
      fit: StackFit.passthrough,
      children: [
        ProxiedImage(
          src: widget.imageUrl,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          alignment: widget.alignment,
          semanticLabel: widget.semanticLabel,
          errorBuilder: widget.errorBuilder,
        ),
        if (_loading)
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
