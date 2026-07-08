import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final IconData fallbackIcon;
  final Color backgroundColor;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.radius = 25,
    this.fallbackIcon = Icons.person,
    this.backgroundColor = Colors.purple,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback();
    }

    if (imageUrl!.startsWith('data:image')) {
      try {
        final base64Str = imageUrl!.split(',').last;
        final bytes = base64Decode(base64Str);
        return CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor.withOpacity(0.2),
          backgroundImage: MemoryImage(bytes),
        );
      } catch (e) {
        return _buildFallback();
      }
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: radius * 2,
          height: radius * 2,
          color: backgroundColor.withOpacity(0.1),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Icon(fallbackIcon, size: radius, color: Colors.white),
    );
  }
}
