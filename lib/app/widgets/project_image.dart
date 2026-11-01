import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/project_image_url.dart';

/// Shared project image rendering for every investor project surface.
class ProjectImage extends StatelessWidget {
  const ProjectImage({super.key, required ProjectModel this.project, this.width, required this.height, this.placeholder})
      : imageUrl = null, updatedAt = null, label = null;
  const ProjectImage.url({super.key, required this.imageUrl, this.updatedAt, this.label, this.width, required this.height, this.placeholder})
      : project = null;
  final ProjectModel? project;
  final String? imageUrl, label;
  final DateTime? updatedAt;
  final double? width;
  final double height;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final base = Get.isRegistered<ApiService>()
        ? Get.find<ApiService>().mediaApiBaseUrl
        : ApiService.defaultBaseUrl;
    final url = projectImageUrl(project?.imageUrl ?? imageUrl, apiBaseUrl: base, updatedAt: project?.updatedAt ?? updatedAt);
    Widget fallback() => placeholder ?? ColoredBox(
      color: AppColors.primaryDark,
      child: Center(child: Icon(Icons.landscape_outlined, color: Colors.white70, size: height < 80 ? 24 : 40)),
    );
    return SizedBox(
      width: width,
      height: height,
      child: url == null ? fallback() : Image.network(
        url,
        key: ValueKey(url),
        width: width,
        height: height,
        fit: BoxFit.cover,
        semanticLabel: project?.name ?? label,
        gaplessPlayback: false,
        errorBuilder: (_, error, stack) => fallback(),
        frameBuilder: (_, child, frame, synchronous) => frame != null ? child : Stack(
          fit: StackFit.expand,
          children: [fallback(), const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))],
        ),
      ),
    );
  }
}
